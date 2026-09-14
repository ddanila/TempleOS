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

#include "/Kernel/I386/Cpu.HH"
I64 I386LexStringToken(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines)
{
  U8 chunk[STR_LEN],*text=0,*next;
  I64 length=0,count,i; Bool done; U32 flags;
  if(!cc || !compiled_lines) return -1;
  flags=I386IrqSave;
  if(cc->cur_str && I386HeapSize(heap,cc->cur_str)<1) { I386IrqRestore(flags); return -1; }
  I386IrqRestore(flags);
  cc->flags|=CCF_IN_QUOTES;
  do {
    count=I386LexStringChunk(heap,cc,chunk,STR_LEN,&done,compiled_lines);
    if(count<=0 || length>0xFFFFFFFF-23-count) goto string_failed;
    flags=I386IrqSave;
    next=I386HeapAlloc(heap,length+count,FALSE);
    I386IrqRestore(flags);
    if(!next) goto string_failed;
    for(i=0;i<length;i++) next[i]=text[i];
    for(i=0;i<count;i++) next[length+i]=chunk[i];
    flags=I386IrqSave;
    if(text) I386HeapFree(heap,text);
    I386IrqRestore(flags);
    text=next; length+=count;
  } while(!done);
  flags=I386IrqSave;
  if(cc->cur_str && !I386HeapFree(heap,cc->cur_str)) {
    I386IrqRestore(flags); goto string_failed;
  }
  cc->cur_str=text; cc->cur_str_len=length; cc->token=TK_STR;
  cc->flags&=~CCF_IN_QUOTES;
  I386IrqRestore(flags);
  if(I386LexRawChar(heap,cc,compiled_lines)<0) return -1;
  cc->flags|=CCF_USE_LAST_U16;
  return TK_STR;
string_failed:
  flags=I386IrqSave;
  if(text) I386HeapFree(heap,text);
  I386IrqRestore(flags);
  return -1;
}
