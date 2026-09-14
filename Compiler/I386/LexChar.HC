#include "/Compiler/I386/LexChar.HH"
#include "/Compiler/LexChar.HC"
I64 I386LexChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines)
{
  CLexCharSource source;
  CI386LexCharSource native;
  I64 token;
  if(!cc || !compiled_lines || cc->flags&CCF_NO_CHAR_CONST) return -1;
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexSourceRead;
  token=LexCharBody(cc,&source);
  if(token<0) return token;
  if(I386LexRawChar(heap,cc,compiled_lines)<0) return -1;
  cc->flags|=CCF_USE_LAST_U16;
  return token;
}
