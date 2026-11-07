I64 fne_case=0;
CDoc *fne_doc;
U0 FNELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 FNEReady(CTask *caller)
{
  U8 *s;
  while(caller->display_doc!=fne_doc || caller->put_doc!=fne_doc || sys_focus_task!=caller)Yield;
  s=MStrPrint("FIND EDITOR ARMED %d\n",fne_case);FNELog(s);Free(s);
}
Bool FNEEvent(CDoc *doc,I64 data,I64 ch,I64 sc)
{
  U8 *s;
  if(!ch && sc.u8[0]==SC_F3 && !(sc&SCF_KEY_DESC)) {
    s=MStrPrint("FIND EDITOR RECEIVED %d\n",fne_case);FNELog(s);Free(s);
  }
  return FALSE;
}
U0 FNPhysicalKey(CDoc *doc,I64 ch=0,I64 sc=0)
{
  CTask *observer,*old_focus=sys_focus_task;
  I64 inhibit=Fs->win_inhibit,flags=Fs->display_flags;
  if(sc&SCF_KEY_DESC){DocPutKey(doc,ch,sc);return;}
  if(fne_case>=8){DocPutKey(doc,ch,sc);fne_case++;return;}
  if(doc->user_put_key)throw('Callback',TRUE);
  doc->user_put_key=&FNEEvent;fne_doc=doc;
  Fs->win_inhibit&=~WIF_SELF_FOCUS;LBts(&Fs->display_flags,DISPLAYf_SHOW);WinFocus(Fs);
  observer=Spawn(&FNEReady,Fs,"Find key observer",-1,Fs,16384);
  DocEd(doc,DOF_DONT_HOME);
  while(TaskValidate(observer))Yield;
  doc->user_put_key=NULL;fne_case++;
  Fs->win_inhibit=inhibit;Fs->display_flags=flags;
  if(TaskValidate(old_focus))WinFocus(old_focus);
}
