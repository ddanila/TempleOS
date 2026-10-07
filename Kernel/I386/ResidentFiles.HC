//Mounted-service cache. Callers hold IF clear; entries own stored bytes.
CI386ResidentFile *I386ResidentFind(CI386FileVolumes *volumes,U8 *name)
{
  CI386ResidentFile *entry=volumes->resident;
  I64 i;
  while(entry) {
    i=0; while(name[i] && name[i]==entry->name[i]) i++;
    if(name[i]==entry->name[i]) return entry;
    entry=entry->next;
  }
  return 0;
}
Bool I386ResidentStore(CI386FileVolumes *volumes,CI386Heap *heap,U8 *name,U8 *data,I64 size,Bool resident)
{
  CI386ResidentFile *entry=0,*old,*previous=0,*cursor;
  I64 length=0,i;
  if(resident) {
    heap=volumes->resident_heap; if(!heap) return FALSE;
    while(name[length]) length++;
    if(size<0 || size>0x7FFFFFFF-length-sizeof(CI386ResidentFile)-2) return FALSE;
    entry=I386HeapAlloc(heap,sizeof(CI386ResidentFile)+length+size+2,TRUE);
    if(!entry) return FALSE;
    entry->heap=heap; entry->size=size; entry->name=(entry+1)(U8 *);
    entry->data=entry->name+length+1;
    for(i=0;i<=length;i++) entry->name[i]=name[i];
    for(i=0;i<size;i++) entry->data[i]=data[i];
  }
  old=I386ResidentFind(volumes,name); cursor=volumes->resident;
  while(cursor && cursor!=old) {previous=cursor;cursor=cursor->next;}
  if(old) {
    if(previous) previous->next=old->next; else volumes->resident=old->next;
    I386HeapFree(old->heap,old);
  }
  if(entry) {entry->next=volumes->resident;volumes->resident=entry;}
  return TRUE;
}
U8 *I386ResidentRead(CI386ResidentFile *entry,CI386Heap *heap,I64 *size,I64 *attr,Bool raw)
{
  U8 *result;
  I64 i,bytes=entry->size,attributes=FileAttr(entry->name,0);
  if(!raw && attributes&0x400) result=I386ExpandBuf(heap,entry->data,bytes,&bytes);
  else {
    result=I386HeapAlloc(heap,bytes+1,TRUE);
    if(result) for(i=0;i<bytes;i++) result[i]=entry->data[i];
  }
  if(result) {if(size)*size=bytes;if(attr)*attr=attributes;}
  return result;
}
