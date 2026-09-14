#include "/Compiler/I386/LexNumber.HH"
#include "/Compiler/LexNumber.HC"
I64 I386LexNumber(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines)
{
  CLexCharSource source;
  CI386LexCharSource native;
  I64 token;
  if(!cc || !compiled_lines || (ch!='.' && !('0'<=ch<='9'))) return -1;
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexSourceRead;
  token=LexNumberBody(cc,ch,&source);
  if(token<0 || I386LexRawChar(heap,cc,compiled_lines)<0) return -1;
  cc->flags|=CCF_USE_LAST_U16;
  return token;
}
