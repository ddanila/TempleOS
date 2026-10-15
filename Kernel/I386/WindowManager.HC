//Resident managed refresh, with the kernel root supervising actual task death.
Bool native_window_started;
CTask *native_window_anchor;
I64 native_window_retry_jiffy;

Bool NativeWindowNeeded(Bool coverage=FALSE)
{//Admission is non-yielding; no task/document pointer escapes this scan.
  CTask *task=sys_winmgr_task;
  CDoc *doc;
  if(!native_window_started || !TaskValidate(task))return FALSE;
  if(TaskValidate(sys_focus_task) &&
      !Bt(&sys_focus_task->display_flags,DISPLAYf_NOT_RAW))return FALSE;
  do {
    if(!TaskValidate(task))return FALSE;
    if(task!=native_window_worker && !NativeRenderOwnerClosing(task) &&
        Bt(&task->display_flags,DISPLAYf_SHOW) &&
        (!coverage || Bt(gr.win_uncovered_bitmap,task->win_z_num))) {
      doc=DocDisplay(task);
      //Default transcript/editor views still use the retained console bridge.
      if(doc && doc!=DocPut(task) || task->draw_it ||
          task->next_ctrl!=&task->next_ctrl)return TRUE;
    }
    task=task->next_task;
  } while(task!=sys_winmgr_task);
  return FALSE;
}
Bool NativeWindowOwnsView()
{
  return native_window_started && TaskValidate(native_window_worker) &&
    !Bt(&native_window_worker->task_flags,TASKf_SUSPENDED) && NativeWindowNeeded(TRUE);
}
Bool NativeWindowAdmit() { return NativeWindowNeeded(TRUE); }
U0 NativeWindowCancel() { throw('WinAbort',TRUE); }
U0 NativeWindowWorkerCleanup(CI386Task *task)
{
  if(native_window_worker!=task)return;
  if(gr.dc && gr.dc->win_task==task)gr.dc->win_task=graphics_owner;
  if(gr.dc2 && gr.dc2->win_task==task)gr.dc2->win_task=graphics_owner;
  sys_winmgr_task=native_window_anchor;
  native_window_worker=NULL;
}
U0 NativeWindowReport(I64 ch,I64 number)
{
  CTask *task=NULL;
  if(number>0)task=NativeWindowFind(number);
  if(task && task!=Fs)LBtr(&task->display_flags,DISPLAYf_SHOW);
  KernelLog("WINMGR window exception ");KernelHex(ch);KernelLog(" ");
  KernelHex(number);KernelLog("\n");
  try {
    NativePrint("Exception in WinMgr: Update Task Win\nExcept:%c:\n",ch);
    NativePrint("%P:%P:%P:%P:%P:%P:%P:%P\n",Fs->except_callers[0],
      Fs->except_callers[1],Fs->except_callers[2],Fs->except_callers[3],
      Fs->except_callers[4],Fs->except_callers[5],Fs->except_callers[6],Fs->except_callers[7]);
  } catch { Fs->catch_except=TRUE; }
}
U0 NativeWindowWorker(U8 *data)
{
  I64 ch,number;
  SetRFlags(GetRFlags|0x200);
  while(TRUE) {
    Fs->task_end_cb=&NativeWindowCancel;
    native_window_fault_task=0;
    try {
      NativeWindowDerived;
      if(NativeWindowNeeded())
        NativeGraphicsPresentChecked(&NativeWindowListDraw,FALSE,&NativeWindowAdmit);
    } catch {
      ch=Fs->except_ch;number=native_window_fault_task;
      Fs->catch_except=TRUE;
      if(ch!='WinAbort' && ch!='DocGone') {
        NativeWindowReport(ch,number);
        (*native_window_sleep)(3000);
      }
    }
    (*native_window_sleep)(33);
  }
}
U0 NativeWinMgrEnsure()
{//Called by the kernel idle root as well as the initial startup transaction.
  CI386Task *worker;
  if(!native_window_started || TaskValidate(native_window_worker) ||
      NativeJiffies<native_window_retry_jiffy)return;
  try {
    worker=(*native_user_providers.spawn)(&NativeWindowWorker,NULL,"WinMgr",-1,
      native_window_anchor,16384,256);
    if(!worker)throw('OutMem',TRUE);
    worker->cleanup=&NativeWindowWorkerCleanup;
    worker->display_flags=1<<DISPLAYf_SHOW|1<<DISPLAYf_NOT_RAW|1<<DISPLAYf_NO_BORDER;
    worker->text_attr=0xF0;
    worker->win_left=worker->win_top=0;worker->win_right=79;worker->win_bottom=59;
    TaskDerivedValsUpdate(worker,FALSE);
    NativeWindowTaskRemove(worker);NativeWindowTaskInsert(worker,native_window_anchor);
    native_window_worker=worker;sys_winmgr_task=worker;
    gr.dc->win_task=worker;
    WinZBufUpdate;
    KernelLog("WINMGR started ");KernelHex(worker->task_num);KernelLog("\n");
  } catch {
    if(Fs->except_ch=='OutMem') {
      Fs->catch_except=TRUE;native_window_retry_jiffy=NativeJiffies+1000;
      KernelLog("WINMGR restart deferred\n");
    }
  }
}
Bool NativeWinMgrStart()
{
  if(!NativeGraphicsReady)return FALSE;
  if(!native_window_started) {
    native_window_anchor=sys_winmgr_task;native_window_started=TRUE;
  }
  NativeWinMgrEnsure;
  return TaskValidate(native_window_worker);
}
