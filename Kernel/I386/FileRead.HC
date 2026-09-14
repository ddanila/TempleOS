#include "/Kernel/I386/FileRead.HH"
#include "/Kernel/I386/Cpu.HH"
U8 *I386RedSeaReadAll(CI386RedSea *volume,CI386Heap *heap,CI386RedSeaEntry *entry,I64 *size)
{
  U8 *buffer;
  if(GetRFlags&0x200 || !heap || !entry || entry->size<0 || entry->size>0xFFFFFFFF-24 ||
      (entry->attr&0x310) || !(entry->attr&0x800)) return 0;
  buffer=I386HeapAlloc(heap,entry->size+1,FALSE);
  if(!buffer) return 0;
  if(I386RedSeaRead(volume,entry,0,buffer,entry->size)!=entry->size) {
    I386HeapFree(heap,buffer); return 0;
  }
  buffer[entry->size]=0;
  if(size) *size=entry->size;
  return buffer;
}
U8 *I386RedSeaFileRead(CI386RedSea *volume,CI386Heap *heap,I64 directory,U8 *path,I64 *size)
{
  CI386RedSeaEntry entry;
  U8 *result=0;
  I64 bytes;
  if(GetRFlags&0x200 || !heap || !I386RedSeaBegin(volume)) return 0;
  if(I386RedSeaResolve(volume,directory,path,&entry)==1) result=I386RedSeaReadAll(volume,heap,&entry,&bytes);
  if(!I386RedSeaEnd(volume)) { if(result) I386HeapFree(heap,result); return 0; }
  if(result && size) *size=bytes;
  return result;
}
