I64 pke_case=0;
CDoc *pke_doc;
U0 PKELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PKEObserve(CTask *caller)
{
  CTask *old_popup=caller->popup_task;U8 *s;
  while(caller->display_doc!=pke_doc || caller->put_doc!=pke_doc)Yield;
  s=MStrPrint("PICKER KEY ARMED %d\n",pke_case);PKELog(s);Free(s);
  while(caller->popup_task==old_popup)Yield;
  while(caller->popup_task!=old_popup)Yield;
  s=MStrPrint("PICKER KEY CLOSED %d\n",pke_case);PKELog(s);Free(s);
}
U0 PKPhysicalKey(CDoc *doc,I64 ch=0,I64 sc=0)
{
  CTask *observer,*old_focus=sys_focus_task;
  I64 inhibit=Fs->win_inhibit,flags=Fs->display_flags;
  if(sc&SCF_KEY_DESC) {DocPutKey(doc,ch,sc);return;}
  Fs->win_inhibit&=~WIF_SELF_FOCUS;LBts(&Fs->display_flags,DISPLAYf_SHOW);WinFocus(Fs);
  pke_doc=doc;observer=Spawn(&PKEObserve,Fs,"Picker editor observer",-1,Fs,16384);
  DocEd(doc,DOF_DONT_HOME);
  while(TaskValidate(observer))Yield;pke_case++;
  Fs->win_inhibit=inhibit;Fs->display_flags=flags;
  if(TaskValidate(old_focus))WinFocus(old_focus);
}
