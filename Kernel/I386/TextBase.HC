#include "/Kernel/TextBaseCore.HC"
//Native hardware text-base staging surface; presentation integration is separate.
U32 i386_text_storage[4802];
U32 *i386_text_base;
U0 NativeTextBaseInit()
{
  i386_text_base=i386_text_storage+1;
  i386_text_storage[0]=0xAB1234CD;
  i386_text_storage[4801]=0xEF567890;
}
Bool TextChar(CTask *task,Bool border=FALSE,I64 x,I64 y,I64 value)
{ return TextBaseCharCore(i386_text_base,80,60,task,border,x,y,value); }
Bool TextLenStr(CTask *task,I64 x,I64 y,I64 length,I64 attr,U8 *str)
{ return TextBaseStrCore(i386_text_base,80,60,task,x,y,length,attr,str); }
Bool TextLenAttrStr(CTask *task,I64 x,I64 y,I64 length,U32 *attrs)
{ return TextBaseAttrStrCore(i386_text_base,80,60,task,x,y,length,attrs); }
Bool TextLenAttr(CTask *task,I64 x,I64 y,I64 length,I64 attr)
{ return TextBaseAttrCore(i386_text_base,80,60,task,x,y,length,attr); }
