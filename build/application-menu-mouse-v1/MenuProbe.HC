I64 probe_mouse[3],probe_answer[3];
U0 MenuProbeLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 MenuProbeObserve(U8 *)
{
  while(TRUE) {
    probe_mouse[0]=ms.pos.x;
    probe_mouse[1]=ms.pos.y;
    probe_mouse[2]=ms.lb;
    Sleep(1);
  }
}
U0 MenuProbe()
{
  CTask *observer;
  I64 old_inhibit=Fs->win_inhibit,action,detail;
  U8 line[100];
  MenuPush("Edit { NewEntry(MSG_CMD,0xA74,0x53); }");
  LBtr(&Fs->win_inhibit,WIf_FOCUS_TASK_MENU);
  WinFocus(Fs);
  observer=Spawn(&MenuProbeObserve,NULL,"Menu mouse observer");
  if(!observer)throw('MenuObs',TRUE);
  StrPrint(line,"MENU ready %X\n",probe_mouse);MenuProbeLog(line);
  probe_answer[0]=GetMsg(&action,&detail,1<<MSG_CMD);
  probe_answer[1]=action;probe_answer[2]=detail;
  Kill(observer);
  Fs->win_inhibit=old_inhibit;
  MenuPop;
  StrPrint(line,"EXPORT menu.bin %X 18\n",probe_answer);MenuProbeLog(line);
  MenuProbeLog("MENU done\n");
}
