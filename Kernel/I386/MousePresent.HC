//Pointer uploads use clean backing planes and one uninterrupted display lease.
U0 NativeMouseRestoreRows(U8 **planes,I64 y)
{
  I64 first=y,count=10;
  if(first<0) {count+=first;first=0;}
  if(first<480 && count>0) {
    if(first+count>480)count=480-first;
    if(!I386VgaSplitRows(planes,first,count))KernelStop;
  }
}
U0 NativeMousePresentRows(U8 **planes,I64 old_y,I64 x,I64 y,I64 operation)
{//0 show, 1 move, 2 hide. No allocation/yield between XOR and restoration.
  if(operation)NativeMouseRestoreRows(planes,old_y);
  if(operation!=2 && y<480 && y+10>0) {
    MousePlaneSplitXor(planes,x,y);
    NativeMouseRestoreRows(planes,y);
    MousePlaneSplitXor(planes,x,y);
  }
}
Bool NativeMouseBackingMatches(U8 **planes,CNativeTerminal *terminal)
{
  I64 p;
  Bool raw=TRUE,graphics=NativeGraphicsReady;
  if(!planes || !terminal)return FALSE;
  for(p=0;p<4;p++) {
    if(planes[p]!=terminal->planes+p*38400)raw=FALSE;
    if(planes[p]!=graphics_planes[p])graphics=FALSE;
  }
  return raw || graphics;
}
U0 NativeMousePresentSplit(U8 **planes,I64 old_y,I64 x,I64 y,I64 operation)
{
  CNativeTerminal *terminal;
  CTask *task;
  I64 task_num,epoch;
  CNativeGraphicsScope scope;
  Bool borrowed=FALSE;
  if(!planes)return;
  if(!graphics_owner) {
    NativeMousePresentRows(planes,old_y,x,y,operation);return;
  }
  terminal=NativeTerminalFind(Fs);
  if(!terminal)terminal=native_terminal_root;
  if(!terminal || sys_focus_task!=terminal->task ||
      !NativeMouseBackingMatches(planes,terminal) ||
      !NativeDisplayViewMatches(planes))return;
  task=terminal->task;task_num=task->task_num;epoch=native_display_epoch;
  try {
    if(!NativeGraphicsTextLock(&scope))goto mouse_present_done;
    borrowed=TRUE;
    if(!TaskValidate(task) || task->task_num!=task_num || sys_focus_task!=task ||
        epoch!=native_display_epoch || !NativeDisplayViewMatches(planes))
      goto mouse_present_done;
    terminal=NativeTerminalFind(task);
    if(!NativeMouseBackingMatches(planes,terminal))goto mouse_present_done;
    NativeMousePresentRows(planes,old_y,x,y,operation);
mouse_present_done:;
  } catch {
    if(borrowed)NativeGraphicsTextUnlock(&scope);
  }
  if(borrowed)NativeGraphicsTextUnlock(&scope);
}
U0 NativeDocMouseShowSplit(U8 **planes,I64 x,I64 y)
{ NativeMousePresentSplit(planes,0,x,y,0); }
U0 NativeDocMouseShow(U8 *planes,I64 x,I64 y)
{
  U8 *split[4];I64 p;
  if(!planes)return;
  for(p=0;p<4;p++)split[p]=planes+p*38400;
  NativeDocMouseShowSplit(split,x,y);
}
U0 NativeMousePlaneMoveSplit(U8 **planes,I64 old_x,I64 old_y,I64 x,I64 y)
{ NativeMousePresentSplit(planes,old_y,x,y,1); }
U0 NativeMousePlaneMove(U8 *planes,I64 old_x,I64 old_y,I64 x,I64 y)
{
  U8 *split[4];I64 p;
  if(!planes)return;
  for(p=0;p<4;p++)split[p]=planes+p*38400;
  NativeMousePlaneMoveSplit(split,old_x,old_y,x,y);
}
U0 NativeDocMouseMove(CDoc *doc,I64 old_x,I64 old_y,I64 x,I64 y)
{
  U8 **planes=NativeGraphicsPlanes;
  if(NativeDocHasSprite(doc) && planes)
    NativeMousePlaneMoveSplit(planes,old_x,old_y,x,y);
  else NativeMousePlaneMove(console_planes,old_x,old_y,x,y);
}
U0 NativeMousePlaneHide(U8 *planes,I64 x,I64 y)
{
  U8 *split[4];I64 p;
  if(!planes)return;
  for(p=0;p<4;p++)split[p]=planes+p*38400;
  NativeMousePresentSplit(split,y,x,y,2);
}
