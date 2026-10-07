U0 DLIdle(U8 *data){while(TRUE)Yield;}
I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,caller,owner;
  CTask *task=Spawn(&DLIdle,NULL,"Link owner",-1,Fs);
  CDoc *doc=DocNew(NULL,task);
  CDocEntry *entry=DocPrint(doc,"$$LK,\"label\",A=\"C:/Owned.HC\"$$");
  U8 *link;
  caller=Fs->data_heap->used_u8s;owner=task->data_heap->used_u8s;
  link=DocEntryLink(doc,entry);
  if(link && !StrCmp(link,"C:/Owned.HC") && link!=entry->aux_str)mask|=1;
  if(Fs->data_heap->used_u8s==caller)mask|=2;
  if(task->data_heap->used_u8s>owner)mask|=4;
  Free(link);
  if(task->data_heap->used_u8s==owner)mask|=8;
  DocDel(doc);if(Kill(task))mask|=16;
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
