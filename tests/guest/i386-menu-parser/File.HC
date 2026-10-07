I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,mask=0,count=0;
  CMenu *m=MenuFile("::/Doc/EdPullDown.DD",17,Fs);
  CMenuEntry *e;
  if(m && m->task==Fs && m->flags==17)mask|=1;
  for(e=m->sub;e;e=e->next)count++;
  if(count==6 && !MenuEntryFind(m,"File/Missing"))mask|=2;
  e=MenuEntryFind(m,"File/Save");
  if(e && e->msg_code==-2 && e->arg1==CH_CTRLS && !e->arg2)mask|=4;
  e=MenuEntryFind(m,"Edit/Undo");
  if(e && e->msg_code==-2 && e->arg1==CH_CTRLH && e->arg2==0x80E0000080E)mask|=8;
  e=MenuEntryFind(m,"Insert/BlinkOff");
  if(e && e->msg_code==2 && e->arg1==CH_CTRLK && e->arg2==0x62500000625)mask|=16;
  MenuDel(m);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
