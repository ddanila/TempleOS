U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 dg_count=0,dg_desc=0,dg_inhibit=0;
Bool DGHook(I64 ch,I64 sc)
{
  dg_count++;if(sc&SCF_KEY_DESC)dg_desc++;
  if(Bt(&Fs->win_inhibit,12))dg_inhibit++;
  return TRUE;
}
U0 DGFilter()
{
  CDoc *d=DocPut;CDocEntry *e;
  for(e=d->head.next;e!=d;e=e->next)e->de_flags|=DOCEF_FILTER_SKIP;
  d->find_replace->filter_lines=1;
}
Bool DGClear()
{
  CDoc *d=DocPut;CDocEntry *e;
  if(d->find_replace->filter_lines)return FALSE;
  for(e=d->head.next;e!=d;e=e->next)
    if(e->de_flags&DOCEF_FILTER_SKIP)return FALSE;
  return !d->owning_task&&!Bt(&d->locked_flags,DOClf_LOCKED);
}
U0 CaptureDocKey()
{
  I64 *v=CAlloc(14*sizeof(I64)),sc=99;
  Bool old_desc=LBts(&Fs->win_inhibit,12),
       old_silent=LBtr(&Fs->display_flags,DISPLAYf_SILENT);
  CKeyDevEntry *hook=KeyDevAdd(&DGHook,NULL,10,TRUE);
  U8 *msg;
  FlushMsgs;
  PostMsg(Fs,MSG_KEY_DOWN,120,SCF_KEY_DESC|0x2D);
  PostMsg(Fs,MSG_KEY_DOWN,97,0x1E);
  v[0]=DocGetKey(&sc);v[1]=sc;v[2]=dg_count;v[3]=dg_desc;
  v[4]=dg_inhibit;v[5]=Bt(&Fs->win_inhibit,12);
  PostMsg(Fs,MSG_KEY_DOWN,98,0x30);v[6]=DocGetKey;
  PostMsg(Fs,MSG_KEY_DOWN,0,0x48);v[7]=DocGetKey(&sc);v[8]=sc;
  DGFilter;PostMsg(Fs,MSG_KEY_DOWN,CH_ESC,1);PostMsg(Fs,MSG_KEY_DOWN,113,0x10);
  v[9]=DocGetKey;v[10]=DGClear;
  DGFilter;PostMsg(Fs,MSG_KEY_DOWN,CH_SHIFT_ESC,1);PostMsg(Fs,MSG_KEY_DOWN,114,0x13);
  v[11]=DocGetKey;v[12]=DGClear;v[13]=dg_count;
  KeyDevRem(hook);LBEqu(&Fs->win_inhibit,12,old_desc);
  LBEqu(&Fs->display_flags,DISPLAYf_SILENT,old_silent);
  msg=MStrPrint("EXPORT doc-getkey.bin %X %X\n",v,14*sizeof(I64));Report(msg);Free(msg);
}
CaptureDocKey;
Report("DONE original document key input\n");
