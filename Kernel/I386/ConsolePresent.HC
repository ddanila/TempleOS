//Synchronous presentation must finish layout, redraw at the resulting viewport,
//then compose those cells. WinMgr normally supplies those successive frames.
class CNativeConsoleDocumentScope:CNativeRenderScope {
  CDoc *doc;
  Bool old_full,saved;
};
U0 NativeConsoleDocumentRelease(CNativeRenderScope *base)
{
  CNativeConsoleDocumentScope *scope=base;
  if(scope->saved) {
    scope->saved=FALSE;
    LBEqu(&scope->doc->flags,DOCf_DO_FULL_REFRESH,scope->old_full);
  }
}
Bool NativeConsolePresentDocument(CTask *task)
{
  CNativeConsoleDocumentScope scope;
  CTask *owner=task;
  I64 frame;
  Bool result=TRUE;
  scope.doc=NULL;scope.saved=FALSE;
  try {
    NativeRenderScopeOpen(&scope,&NativeConsoleDocumentRelease);
    scope.doc=DocDisplay(task);
    if(scope.doc && scope.doc->doc_signature!=DOC_SIGNATURE_VAL)throw('DocGone',TRUE);
    if(scope.doc)owner=scope.doc->mem_task;
    NativeRenderScopeBorrow(&scope,owner,task,scope.doc);
    if(scope.doc) {
      scope.old_full=LBts(&scope.doc->flags,DOCf_DO_FULL_REFRESH);
      scope.saved=TRUE;
    }
    for(frame=0;frame<3;frame++)
      if(!NativeWindowPresent(FALSE)) {result=FALSE;break;}
    NativeConsoleDocumentRelease(&scope);
  } catch {
    NativeConsoleDocumentRelease(&scope);NativeRenderScopeClose(&scope);
  }
  NativeRenderScopeClose(&scope);
  return result;
}

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
    NativePresentationCommit;
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
  if(NativeWindowOwnsView)return;
  while(terminal && surface!=&terminal->surface)terminal=terminal->next;
  if(terminal) {
    task=terminal->task;task_num=task->task_num;
    if(sys_focus_task!=task)return;
  } else if(surface!=&console_default_text || native_terminal_root)return;
  //When the manager is suspended, keep a rich document visible by composing
  //the real window list synchronously instead of replacing it with stale text.
  if(task && NativeWindowNeeded(TRUE)) {
    //Force layout rather than depending on the periodic full-refresh cadence.
    if(!NativeConsolePresentDocument(task)) {
      KernelLog("SUSPENDED DOCUMENT PRESENT FAILED ");KernelHex(Fs->except_ch);KernelLog("\n");
    }
    return;
  }
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
