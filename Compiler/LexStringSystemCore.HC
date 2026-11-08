#include "/Compiler/LexString.HC"
I64 LexSystemChar(U8 *context,CCmpCtrl *cc)
{
  return LexGetChar(cc);
}
I64 LexInStr(CCmpCtrl *cc,U8 *buf,I64 size,Bool *done)
{
  CLexCharSource source;
  source.context=0; source.read=&LexSystemChar;
  return LexStringChunk(cc,buf,size,done,&source);
}
