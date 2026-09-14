#include "/Compiler/I386/LexString.HH"
#include "/Compiler/LexString.HC"
I64 I386LexStringChunk(CI386Heap *heap,CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *compiled_lines)
{
  CLexCharSource source;
  CI386LexCharSource native;
  if(!done) return -1;
  *done=FALSE;
  if(!cc || !compiled_lines || size<0 || (!buf && size>1)) return -1;
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexSourceRead;
  return LexStringChunk(cc,buf,size,done,&source);
}
