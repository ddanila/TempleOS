#include "/Compiler/LexDefine.HC"
Bool LexDefineSystemAppend(U8 *context,U8 *text,I64 count)
{
  CLexDefineBuffer *buffer=context;
  U8 *next=MAlloc(buffer->length+count);
  if(buffer->text) {
    MemCpy(next,buffer->text,buffer->length);
    Free(buffer->text);
  }
  MemCpy(next+buffer->length,text,count);
  buffer->text=next; buffer->length+=count-1;
  return TRUE;
}
