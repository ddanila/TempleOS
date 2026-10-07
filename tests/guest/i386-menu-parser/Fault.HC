I64 mf_caught,mf_returned,mf_delta;
U0 MFOnce()
{
  CMenu *menu=NULL;
  try { menu=MenuNew("File{Open(2,65,0)"); }
  catch { mf_caught++;Fs->catch_except=TRUE; }
  if(menu) { mf_returned++;MenuDel(menu); }
}
I64 JRContract()
{
  I64 base=Fs->data_heap->used_u8s,i,mask=0;
  CCmpCtrl *boundary=Fs->last_cc;
#ifndef I386_PUBLIC_USER_INCLUDED
  I64 old_run_level=sys_run_level;
  Bool old_raw=Raw(ON);
  Bts(&sys_run_level,RLf_ADAM_SERVER);
#endif
  mf_caught=mf_returned=0;
  for(i=0;i<10;i++)MFOnce;
  mf_delta=Fs->data_heap->used_u8s-base;
  if(mf_caught==10)mask|=1;
  if(!mf_delta)mask|=2;
  if(Fs->last_cc==boundary)mask|=4;
  if(!mf_returned)mask|=8;
#ifndef I386_PUBLIC_USER_INCLUDED
  Raw(old_raw);
  sys_run_level=old_run_level;
#endif
  return mask;
}
