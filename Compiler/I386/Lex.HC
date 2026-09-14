#include "/Compiler/I386/Lex.HH"
#include "/Compiler/LexConditional.HC"
class CI386ConditionalInput {
  CI386Heap *heap; CLexPunctTables *tables; U8 *macro_filename; I64 *compiled_lines;
  CI386LexIncludeService *includes;
};
I64 I386ConditionalToken(U8 *context,CCmpCtrl *cc)
{
  CI386ConditionalInput *input=context;
  return I386LexNextWithIncludes(input->heap,cc,input->tables,input->macro_filename,input->compiled_lines,input->includes);
}
I64 I386ConditionalSkip(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,U8 *macro_filename,I64 *compiled_lines,Bool stop_else,CI386LexIncludeService *includes)
{
  CI386ConditionalInput input; CI386LexCharSource native; CLexCharSource characters,tokens;
  input.heap=heap; input.tables=tables; input.macro_filename=macro_filename; input.compiled_lines=compiled_lines;
  input.includes=includes;
  native.heap=heap; native.compiled_lines=compiled_lines;
  characters.context=&native; characters.read=&I386LexSourceRead;
  tokens.context=&input; tokens.read=&I386ConditionalToken;
  return LexSkipConditional(cc,&characters,&tokens,1,stop_else);
}
//Match LexExtStr(...,FALSE): only an immediate backslash joins strings.
//Keep every partial result in a control-owned slot across allocation failures.
I64 I386LexHelpIndex(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,
  U8 *macro_filename,I64 *compiled_lines,CI386LexIncludeService *includes)
{
  I64 result,length,count,i,ch;
  U8 *combined;
  U32 irq;
  result=I386LexNextWithIncludes(heap,cc,tables,macro_filename,compiled_lines,includes);
  if(result!=TK_STR) return result;
  irq=I386IrqSave;
  if(cc->cur_help_idx && !I386HeapFree(heap,cc->cur_help_idx)) {
    I386IrqRestore(irq); return -1;
  }
  cc->cur_help_idx=cc->cur_str; cc->cur_str=0; length=cc->cur_str_len;
  I386IrqRestore(irq);
  while(TRUE) {
    ch=I386LexRawChar(heap,cc,compiled_lines);
    if(ch<0) return -1;
    if(ch!='\\') { cc->flags|=CCF_USE_LAST_U16; return TK_STR; }
    result=I386LexNextWithIncludes(heap,cc,tables,macro_filename,compiled_lines,includes);
    if(result<0) return result;
    if(result!=TK_STR) return TK_STR;
    count=cc->cur_str_len;
    if(length<1 || count<1 || length>0x7FFFFFFF-count) return -1;
    irq=I386IrqSave;
    combined=I386HeapAlloc(heap,length+count-1,FALSE);
    I386IrqRestore(irq);
    if(!combined) return -1;
    for(i=0;i<length-1;i++) combined[i]=cc->cur_help_idx[i];
    for(i=0;i<count;i++) combined[length-1+i]=cc->cur_str[i];
    irq=I386IrqSave;
    I386HeapFree(heap,cc->cur_help_idx); I386HeapFree(heap,cc->cur_str);
    cc->cur_help_idx=combined; cc->cur_str=0; length+=count-1;
    I386IrqRestore(irq);
  }
}
I64 I386LexNextWithIncludes(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,
  U8 *macro_filename,I64 *compiled_lines,CI386LexIncludeService *includes)
{
  I64 ch,result,keyword; Bool take;
  if(!heap || !cc || !cc->lex_include_stk || !compiled_lines || !tables ||
      !tables->first || !tables->second || !tables->third) return -1;
  cc->last_line_num=cc->lex_include_stk->line_num;
  while(TRUE) {
    ch=I386LexRawChar(heap,cc,compiled_lines);
    if(ch<0 || ch>TK_TKS_NUM) return -1;
    switch(ch) {
      case 0: return cc->token=TK_EOF;
      case '@':
        if(cc->flags&CCF_KEEP_AT_SIGN) goto lex_literal;
      case TK_SUPERSCRIPT: case TK_SUBSCRIPT: case TK_NORMALSCRIPT:
      case 'A'...'Z': case 'a'...'z': case '_': case 128...255:
        result=I386LexIdentToken(heap,cc,ch,macro_filename,compiled_lines);
        if(result!=-2) return result;
        break;
      case '0'...'9': case '.': return I386LexNumber(heap,cc,ch,compiled_lines);
      case '"': return I386LexStringToken(heap,cc,compiled_lines);
      case 39:
        if(cc->flags&CCF_NO_CHAR_CONST) break;
        result=I386LexChar(heap,cc,compiled_lines);
        if(result==-2) return -5;
        return result;
      case '#':
        if(cc->flags&CCF_KEEP_SIGN_NUM) goto lex_literal;
        result=I386LexNextWithIncludes(heap,cc,tables,macro_filename,compiled_lines,includes);
        if(result<0) return result;
        if(result!=TK_IDENT || !cc->hash_entry || !(cc->hash_entry->type&HTT_KEYWORD)) return -4;
        keyword=cc->hash_entry(CHashGeneric *)->user_data0;
        switch(keyword) {
          case KW_INCLUDE:
            if(!includes || !includes->push) return -4;
            result=I386LexNextWithIncludes(heap,cc,tables,macro_filename,compiled_lines,includes);
            if(result<0) return result;
            if(result!=TK_STR) goto lex_finish;
            if(!(*includes->push)(includes->context,heap,cc,cc->cur_str)) return -1;
            break;
          case KW_HELP_INDEX:
            result=I386LexHelpIndex(heap,cc,tables,macro_filename,compiled_lines,includes);
            if(result<0) return result;
            if(result!=TK_STR) goto lex_finish;
            break;
          case KW_DEFINE:
            cc->flags|=CCF_NO_DEFINES;
            result=I386LexNextWithIncludes(heap,cc,tables,macro_filename,compiled_lines,includes);
            if(result==TK_IDENT && !I386LexDefinePublish(heap,cc,compiled_lines)) result=-1;
            cc->flags&=~CCF_NO_DEFINES;
            if(result<0) return result;
            break;
          case KW_IFDEF: case KW_IFNDEF:
            if(cc->flags&CCF_IN_IF) {
              ch=TK_IFDEF; if(keyword==KW_IFNDEF) ch=TK_IFNDEF;
              goto lex_literal;
            }
            cc->flags|=CCF_NO_DEFINES;
            result=I386LexNextWithIncludes(heap,cc,tables,macro_filename,compiled_lines,includes);
            cc->flags&=~CCF_NO_DEFINES;
            if(result<0) return result;
            if(result!=TK_IDENT) goto lex_finish;
            take=cc->hash_entry!=0; if(keyword==KW_IFNDEF) take=!take;
            if(!take) {
              result=I386ConditionalSkip(heap,cc,tables,macro_filename,compiled_lines,TRUE,includes);
              if(result<0) return result;
              if(!result) goto lex_finish;
            }
            break;
          case KW_IFAOT: case KW_IFJIT:
            if(cc->flags&CCF_IN_IF) { ch=TK_IFAOT; goto lex_literal; }
            take=(cc->flags&CCF_AOT_COMPILE)!=0; if(keyword==KW_IFJIT) take=!take;
            if(!take) {
              result=I386ConditionalSkip(heap,cc,tables,macro_filename,compiled_lines,TRUE,includes);
              if(result<0) return result;
              if(!result) goto lex_finish;
            }
            break;
          case KW_ELSE:
            if(cc->flags&CCF_IN_IF) { ch=TK_ELSE; goto lex_literal; }
            result=I386ConditionalSkip(heap,cc,tables,macro_filename,compiled_lines,FALSE,includes);
            if(result<0) return result;
            if(!result) goto lex_finish;
            break;
          case KW_ENDIF:
            if(cc->flags&CCF_IN_IF) { ch=TK_ENDIF; goto lex_literal; }
            break;
          case KW_IF:
            if(cc->flags&CCF_IN_IF) { ch=TK_IF; goto lex_literal; }
          default: return -4;
        }
        break;
      case 10:
        if(!(cc->flags&CCF_KEEP_NEW_LINES)) break;
      case TK_INS_BIN: case TK_INS_BIN_SIZE:
lex_literal:
        cc->token=ch;
lex_finish:
        if(I386LexRawChar(heap,cc,compiled_lines)<0) return -1;
        cc->flags|=CCF_USE_LAST_U16;
        return cc->token;
      case '!': case '$$'...'&': case '('...'-': case '/': case ':'...'?':
      case '[': case ']'...'^': case '{'...'~': case '`':
        result=I386LexPunct(heap,cc,ch,tables,compiled_lines);
        if(result!=-2) return result;
        break;
    }
  }
}

I64 I386LexNext(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,U8 *macro_filename,I64 *compiled_lines)
{
  return I386LexNextWithIncludes(heap,cc,tables,macro_filename,compiled_lines,0);
}
