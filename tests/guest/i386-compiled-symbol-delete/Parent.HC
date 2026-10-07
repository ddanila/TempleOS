I64 HDParentGlobal=42,hd_parent_mask=0;
Bool hd_parent_done=FALSE;
U0 HDParentWorker(U8 *data)
{
  I64 own=Fs->data_heap->used_u8s;
  CHashTable *table=data;
  CHashSrcSym *entry=HashFind("HDParentGlobal",Fs->hash_table,HTT_GLBL_VAR);
  if(entry)hd_parent_mask|=1;
  if(entry && HashRemDel(entry,table))hd_parent_mask|=2;
  if(!HashFind("HDParentGlobal",Fs->hash_table,HTT_GLBL_VAR))hd_parent_mask|=4;
  if(Fs->data_heap->used_u8s==own)hd_parent_mask|=32;
  hd_parent_done=TRUE;
  while(TRUE)Yield;
}
I64 JRContract()
{
  I64 mask;
  CTask *task=Spawn(&HDParentWorker,Fs->hash_table,"Parent delete",-1,Fs);
  while(!hd_parent_done)Yield;
  mask=hd_parent_mask;
  if(!HashFind("HDParentGlobal",Fs->hash_table,HTT_GLBL_VAR))mask|=8;
  if(Kill(task))mask|=16;
  return mask;
}
