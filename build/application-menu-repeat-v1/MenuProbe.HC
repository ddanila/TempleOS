I64 probe_mouse[8],probe_answer[6];
U0 MenuProbeLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 MenuProbeObserve(U8 *)
{
  while(TRUE) {
    probe_mouse[0]=ms.pos.x;
    probe_mouse[1]=ms.pos.y;
    probe_mouse[2]=ms.lb;
    probe_mouse[3]++;
    MouseGet(probe_mouse+4,probe_mouse+5,probe_mouse+6,probe_mouse+7);
    Sleep(1);
  }
}
U0 MenuProbe()
{
  CTask *observer;
  I64 old_inhibit=Fs->win_inhibit,action,detail,i;
  U8 line[100];
  MenuPush("Edit { NewEntry(MSG_CMD,0xA74,0x53); }");
  LBtr(&Fs->win_inhibit,WIf_FOCUS_TASK_MENU);
  WinFocus(Fs);
  observer=Spawn(&MenuProbeObserve,NULL,"Menu mouse observer");
  if(!observer)throw('MenuObs',TRUE);
  while(!probe_mouse[3])Sleep(1);
  StrPrint(line,"MENU ready %X\n",probe_mouse);MenuProbeLog(line);
  for(i=0;i<2;i++) {
    probe_answer[3*i]=GetMsg(&action,&detail,1<<MSG_CMD);
    probe_answer[3*i+1]=action;
    probe_answer[3*i+2]=detail;
    StrPrint(line,"MENU command %d\n",i+1);MenuProbeLog(line);
  }
  Kill(observer);
  Fs->win_inhibit=old_inhibit;
  MenuPop;
  StrPrint(line,"EXPORT menu.bin %X 30\n",probe_answer);MenuProbeLog(line);
  MenuProbeLog("MENU done\n");
}
