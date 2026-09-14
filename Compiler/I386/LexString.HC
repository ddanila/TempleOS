#include "/Compiler/I386/LexString.HH"
#include "/Compiler/LexString.HC"
class CI386LexCharSource {
  CI386Heap *heap;
  I64 *compiled_lines;
};
I64 I386LexStringChar(U8 *context,CCmpCtrl *cc)
{
  CI386LexCharSource *source=context;
  return I386LexRawChar(source->heap,cc,source->compiled_lines);
}
I64 I386LexStringChunk(CI386Heap *heap,CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *compiled_lines)
{
  CLexCharSource source;
  CI386LexCharSource native;
  if(!done) return -1;
  *done=FALSE;
  if(!cc || !compiled_lines || size<0 || (!buf && size>1)) return -1;
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexStringChar;
  return LexStringChunk(cc,buf,size,done,&source);
}
