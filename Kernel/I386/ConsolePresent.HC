//Raw terminal uploads share the graphics lease, without retaining stale surfaces.
U0 NativeConsolePresentRows(CI386Text *surface)
{
  I64 rows,i,p;
  U8 *planes[4];
  U8 message[13],*prefix="VGA ROWS ";
  if(!surface || !surface->planes)KernelStop;
  for(p=0;p<4;p++)planes[p]=surface->planes+p*38400;
  //Partial text rows cannot restore a different graphics/terminal image.
  if(!NativeDisplayViewMatches(planes)) {
    surface->dirty_first=0;surface->dirty_last=60;
  }
  rows=I386TextPresent(surface);
  if(rows<0) KernelStop;
  if(rows) {
    NativeDisplayViewCommit(planes);
    NativeWinRefreshCommit;
    for(i=0;i<9;i++) message[i]=prefix[i];
    message[9]='0'+rows/10; message[10]='0'+rows%10;
    message[11]=10; message[12]=0; KernelLog(message);
  }
}

U0 ConsolePresentText(CI386Text *surface)
{
  CNativeTerminal *terminal=native_terminal_head;
  CTask *task=NULL;
  I64 task_num=0;
  CNativeGraphicsScope scope;
  Bool borrowed=FALSE;
  //Before graphics startup there is no competing frame owner or managed wait.
  if(!graphics_owner) { NativeConsolePresentRows(surface);return; }
  while(terminal && surface!=&terminal->surface)terminal=terminal->next;
  if(terminal) {
    task=terminal->task;task_num=task->task_num;
    if(sys_focus_task!=task)return;
  } else if(surface!=&console_default_text || native_terminal_root)return;
  try {
    //Recursion leaves dirty rows pending; foreign callers wait cooperatively.
    if(!NativeGraphicsTextLock(&scope))goto console_present_done;
    borrowed=TRUE;
    if(task) {
      //A different task may have changed focus or retired this terminal while
      //we yielded. Compare identity before touching the saved surface pointer.
      if(!TaskValidate(task) || task->task_num!=task_num || sys_focus_task!=task)
        goto console_present_done;
      terminal=NativeTerminalFind(task);
      if(!terminal || surface!=&terminal->surface)goto console_present_done;
    } else if(native_terminal_root)goto console_present_done;
    NativeConsolePresentRows(surface);
console_present_done:;
  } catch {
    if(borrowed)NativeGraphicsTextUnlock(&scope);
  }
  if(borrowed)NativeGraphicsTextUnlock(&scope);
}
