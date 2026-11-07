I64 ske_case=0;
CDoc *ske_doc=NULL;
U0 SKELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 SKEReady(CTask *caller)
{
  U8 *s;
  while(caller->display_doc!=ske_doc || caller->put_doc!=ske_doc || sys_focus_task!=caller)Yield;
  s=MStrPrint("SEARCH EDITOR ARMED %d\n",ske_case);SKELog(s);Free(s);
  while(!sk_forms || (ske_case==2 || ske_case==3) && !sk_menus ||
      caller->display_doc!=ske_doc || caller->popup_task ||
      !Bt(&caller->task_flags,TASKf_AWAITING_MSG))Yield;
  s=MStrPrint("SEARCH EDITOR CLOSED %d\n",ske_case);SKELog(s);Free(s);
}
Bool SKEEvent(CDoc *doc,I64 data,I64 ch,I64 sc)
{
  U8 *s;
  if(ch==CH_CTRLF && !(sc&SCF_KEY_DESC)) {
    s=MStrPrint("SEARCH EDITOR RECEIVED %d\n",ske_case);SKELog(s);Free(s);
  }
  return FALSE;
}
U0 SKPhysicalKey(CDoc *doc,I64 ch=0,I64 sc=0)
{
  CTask *observer,*old_focus=sys_focus_task;
  I64 inhibit=Fs->win_inhibit,flags=Fs->display_flags;
  if(sc&SCF_KEY_DESC){DocPutKey(doc,ch,sc);return;}
  //Alt suppression and absent Ctrl scan flag are direct API cases.
  if(ske_case==5 || ske_case==6 || ske_case==8){DocPutKey(doc,ch,sc);ske_case++;return;}
  if(doc->user_put_key)throw('Callback',TRUE);
  doc->user_put_key=&SKEEvent;ske_doc=doc;
  Fs->win_inhibit&=~WIF_SELF_FOCUS;LBts(&Fs->display_flags,DISPLAYf_SHOW);WinFocus(Fs);
  observer=Spawn(&SKEReady,Fs,"Search key observer",-1,Fs,16384);
  DocEd(doc,DOF_DONT_HOME);
  while(TaskValidate(observer))Yield;
  doc->user_put_key=NULL;ske_case++;
  Fs->win_inhibit=inhibit;Fs->display_flags=flags;
  if(TaskValidate(old_focus))WinFocus(old_focus);
}
