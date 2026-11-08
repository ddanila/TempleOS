#include "/Compiler/LexIdent.HC"
Bool LexIdentSystemInclude(U8 *context,CCmpCtrl *cc,CHashDefineStr *entry)
{
  LexIncludeStr(cc,entry->str,StrNew(entry->data),FALSE);
  cc->lex_include_stk->flags|=LFSF_DEFINE;
  return TRUE;
}
Bool LexIdentSystemPublish(U8 *context,CCmpCtrl *cc,U8 *name,I64 length,CHash *entry)
{
  cc->hash_entry=entry;
  Free(cc->cur_str);
  cc->cur_str=StrNew(name);
  cc->cur_str_len=length;
  cc->token=TK_IDENT;
  return TRUE;
}
