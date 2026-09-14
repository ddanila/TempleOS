#include "/Compiler/LexConditional.HH"
I64 LexSkipConditional(CCmpCtrl *cc,CLexCharSource *characters,CLexCharSource *tokens,I64 depth,Bool stop_else)
{
  I64 ch,token,keyword;
  if(!cc || !characters || !characters->read || !tokens || !tokens->read || depth<1) return -1;
  do {
    ch=(*characters->read)(characters->context,cc);
    if(ch<0) return ch;
    if(!ch) { cc->token=TK_EOF; return 0; }
    if(ch=='#') {
      token=(*tokens->read)(tokens->context,cc);
      if(token<0) return token;
      if(!token) { cc->token=TK_EOF; return 0; }
      keyword=-1;
      if(cc->token==TK_IDENT && cc->hash_entry && cc->hash_entry->type&HTT_KEYWORD)
        keyword=cc->hash_entry(CHashGeneric *)->user_data0;
      if(keyword==KW_IF || keyword==KW_IFDEF || keyword==KW_IFNDEF || keyword==KW_IFAOT || keyword==KW_IFJIT)
        depth++;
      else if(keyword==KW_ENDIF) depth--;
      else if(stop_else && keyword==KW_ELSE && depth==1) break;
    }
  } while(depth);
  return 1;
}
