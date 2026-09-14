#include "/Compiler/I386/Lex.HH"
I64 I386LexNext(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,U8 *macro_filename,I64 *compiled_lines)
{
  I64 ch,result;
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
        return -4;
      case 10:
        if(!(cc->flags&CCF_KEEP_NEW_LINES)) break;
      case TK_INS_BIN: case TK_INS_BIN_SIZE:
lex_literal:
        cc->token=ch;
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
