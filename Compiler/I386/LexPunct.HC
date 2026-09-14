#include "/Compiler/I386/LexPunct.HH"
#include "/Compiler/LexPunct.HC"
I64 I386LexPunct(CI386Heap *heap,CCmpCtrl *cc,I64 ch,CLexPunctTables *tables,I64 *compiled_lines)
{
  CLexCharSource source; CI386LexCharSource native;
  I64 token; Bool finish;
  if(!cc || !compiled_lines || !tables || !tables->first || !tables->second || !tables->third) return -1;
  switch(ch) {
    case '!': case '$$'...'&': case '('...'-': case '/': case ':'...'?':
    case '[': case ']'...'^': case '{'...'~': case '`': break;
    default: return -1;
  }
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexSourceRead;
  token=LexPunctBody(cc,ch,&source,tables,&finish);
  if(token<0 || !finish) return token;
  if(I386LexRawChar(heap,cc,compiled_lines)<0) return -1;
  cc->flags|=CCF_USE_LAST_U16;
  return token;
}
