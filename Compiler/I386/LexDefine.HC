#include "/Compiler/I386/LexDefine.HH"
#include "/Compiler/LexDefine.HC"
class CI386LexDefineBuffer { CI386Heap *heap; U8 *text; I64 length; };
Bool I386LexDefineAppend(U8 *context,U8 *text,I64 count)
{
  CI386LexDefineBuffer *buffer=context; U8 *next; I64 i; U32 flags;
  if(count<1 || buffer->length>0xFFFFFFFF-23-count) return FALSE;
  flags=I386IrqSave;
  next=I386HeapAlloc(buffer->heap,buffer->length+count,FALSE);
  I386IrqRestore(flags);
  if(!next) return FALSE;
  for(i=0;i<buffer->length;i++) next[i]=buffer->text[i];
  for(i=0;i<count;i++) next[buffer->length+i]=text[i];
  flags=I386IrqSave;
  if(buffer->text) I386HeapFree(buffer->heap,buffer->text);
  I386IrqRestore(flags);
  buffer->text=next; buffer->length+=count-1;
  return TRUE;
}
U8 *I386LexDefineBody(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines)
{
  CI386LexCharSource native; CLexCharSource source; CLexDefineSink sink;
  CI386LexDefineBuffer buffer; U32 flags;
  if(!heap || !cc || !compiled_lines) return 0;
  native.heap=heap; native.compiled_lines=compiled_lines;
  source.context=&native; source.read=&I386LexSourceRead;
  buffer.heap=heap; buffer.text=0; buffer.length=0;
  sink.context=&buffer; sink.append=&I386LexDefineAppend;
  if(LexDefineRead(cc,&source,&sink)) return buffer.text;
  flags=I386IrqSave;
  if(buffer.text) I386HeapFree(heap,buffer.text);
  I386IrqRestore(flags);
  return 0;
}
