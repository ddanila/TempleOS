I64 JRContract()
{
  I64 mask=0,base=Fs->data_heap->used_u8s;
  CMenu *m=MenuNew("File{Open(2,65,0);Close(3,66,1);}Help{About(4,67,2);}",17,Fs);
  CMenuEntry *e;
  if(m && m->task==Fs && m->flags==17)mask|=1;
  if(m->sub && m->sub->dir && !StrCmp(m->sub->name,"File"))mask|=2;
  e=MenuEntryFind(m,"File/Open");
  if(e && e->msg_code==2 && e->arg1==65 && !e->arg2)mask|=4;
  e=MenuEntryFind(m,"File/Close");
  if(e && e->msg_code==3 && e->arg1==66 && e->arg2==1)mask|=8;
  e=MenuEntryFind(m,"Help/About");
  if(e && e->msg_code==4 && e->arg1==67 && e->arg2==2 && !MenuEntryFind(m,"File/Missing"))mask|=16;
  MenuDel(m);
  if(Fs->data_heap->used_u8s==base)mask|=32;
  return mask;
}
