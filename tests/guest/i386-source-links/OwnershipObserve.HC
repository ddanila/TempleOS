I64 SLTarget(){return 42;}
U0 SLIdle(U8 *data){while(TRUE)Yield;}
I64 JRContract(U8 *expected)
{
  I64 base=Fs->data_heap->used_u8s,mask=0,caller,owner;
  CHashSrcSym *fun=HashFind("SLTarget",Fs->hash_table,HTT_FUN);
  CDbgInfo *saved=fun->dbg_info;
  CTask *task=Spawn(&SLIdle,NULL,"Source owner",-1,Fs);
  U8 *filename,*link,*want=MStrPrint("FL:%s,1",expected);
  fun->dbg_info=NULL;
  caller=Fs->data_heap->used_u8s;owner=task->data_heap->used_u8s;
  filename=SrcFileName(&SLTarget,1,task);
  link=SrcEdLink(&SLTarget,1,task);
  if(filename && !StrCmp(filename,expected))mask|=1;
  if(link && !StrCmp(link,want))mask|=2;
  if(Fs->data_heap->used_u8s==caller)mask|=4;
  if(task->data_heap->used_u8s>owner)mask|=8;
  Free(filename);Free(link);
  if(task->data_heap->used_u8s==owner)mask|=16;
  fun->dbg_info=saved;Free(want);Kill(task);
  U8 *obs=MStrPrint("OBS caller delta %d base %d now %d\n",Fs->data_heap->used_u8s-base,base,Fs->data_heap->used_u8s);
  U8 *cur=obs;while(*cur)OutU8(0xE9,*cur++);Free(obs);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
