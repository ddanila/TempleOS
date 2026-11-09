//Original control coordinates and capture rules, scheduled with owner borrowing.
I64 native_window_control_task;
CCtrl *native_window_control;
Bool native_window_control_right;
U32 native_window_control_gestures;
U0 NativeWindowControlReset()
{
  native_window_control_task=0;native_window_control=NULL;
  native_window_control_gestures=0;
}
Bool NativeWindowControlNeeded()
{//Control input does not require replacing a focused raw terminal's surface.
  CTask *task=sys_winmgr_task;
  if(!native_window_started || !TaskValidate(task))return FALSE;
  if(native_window_control)return TRUE;
  //Retained editor/help/picker scopes still own their existing input path.
  if(NativeLegacyViewActive(sys_focus_task))return FALSE;
  do {
    if(!TaskValidate(task))return FALSE;
    if(task!=native_window_worker && !NativeRenderOwnerClosing(task) &&
        Bt(&task->display_flags,DISPLAYf_SHOW) && task->next_ctrl!=&task->next_ctrl)return TRUE;
    task=task->next_task;
  } while(task!=sys_winmgr_task);
  return FALSE;
}
CTask *NativeWindowControlTarget(I64 x,I64 y)
{//An opaque foreground window blocks controls behind it, even without a doc.
  CTask *task=sys_winmgr_task->last_task;
  while(task!=sys_winmgr_task) {
    if(!TaskValidate(task))return NULL;
    if(!NativeRenderOwnerClosing(task) && Bt(&task->display_flags,DISPLAYf_SHOW) &&
        WinInside(x,y,task,FONT_WIDTH))return task;
    task=task->last_task;
  }
  return NULL;
}
U0 NativeWindowControlRelease(CNativeRenderScope *) {}
Bool NativeWindowControlMember(CTask *task,CCtrl *control)
{
  CCtrl *c;
  if(NativeRenderOwnerClosing(task))return FALSE;
  for(c=task->next_ctrl;c!=&task->next_ctrl;c=c->next)
    if(c==control)return TRUE;
  return FALSE;
}
Bool NativeWindowControlEnabled(CTask *task)
{
  return !Bt(&task->win_inhibit,WIf_SELF_CTRLS) &&
    (!TaskValidate(sys_focus_task) || !Bt(&sys_focus_task->win_inhibit,WIf_FOCUS_TASK_CTRLS));
}
Bool NativeWindowControlHit(CTask *task,I64 x,I64 y)
{
  CNativeRenderScope scope;
  CCtrl *c;
  Bool result=FALSE;
  try {
    NativeRenderScopeOpen(&scope,&NativeWindowControlRelease);
    NativeRenderScopeBorrow(&scope,task,task,NULL);
    for(c=task->next_ctrl;c!=&task->next_ctrl;c=c->next) {
      result=CtrlInside(c,x,y);
      //A custom hit callback may yield and unlink its control.
      if(!NativeWindowControlMember(task,c)){result=FALSE;break;}
      if(result)break;
    }
  } catch {NativeRenderScopeClose(&scope);}
  NativeRenderScopeClose(&scope);return result;
}
U0 NativeWindowControlCall(CTask *task,CCtrl *c,I64 x,I64 y,Bool right,Bool down)
{
  I64 left=task->pix_left,top=task->pix_top;
  if(c->flags&CTRLF_BORDER){left-=FONT_WIDTH;top-=FONT_HEIGHT;}
  native_window_fault_task=task->task_num;
  if(right) {
    if(c->right_click)(*c->right_click)(c,x-left,y-top,down);
  } else if(c->left_click)(*c->left_click)(c,x-left,y-top,down);
  native_window_fault_task=0;
}
Bool NativeWindowControlEdge(CTask *task,I64 x,I64 y,Bool right,Bool down)
{
  CNativeRenderScope scope;
  CCtrl *c;
  Bool hit=FALSE;
  U32 bit=1;
  if(right)bit=2;
  if(!NativeWindowControlEnabled(task))return FALSE;
  try {
    NativeRenderScopeOpen(&scope,&NativeWindowControlRelease);
    NativeRenderScopeBorrow(&scope,task,task,NULL);
    for(c=task->next_ctrl;c!=&task->next_ctrl;c=c->next) {
      hit=CtrlInside(c,x,y);
      if(!NativeWindowControlMember(task,c)){hit=TRUE;break;}
      if(hit) {
        if(down) {
          native_window_control_gestures|=bit;
          if(!right && c->flags&CTRLF_CAPTURE_LEFT_MS ||
              right && c->flags&CTRLF_CAPTURE_RIGHT_MS) {
            native_window_control_task=task->task_num;native_window_control=c;
            native_window_control_right=right;
          }
        }
        NativeWindowControlCall(task,c,x,y,right,down);
        if(native_window_control==c && !NativeWindowControlMember(task,c)) {
          native_window_control=NULL;native_window_control_task=0;
        }
        break;
      }
    }
  } catch {NativeRenderScopeClose(&scope);}
  NativeRenderScopeClose(&scope);return hit;
}
Bool NativeWindowControlCapture(I64 x,I64 y,U32 buttons)
{
  CNativeRenderScope scope;
  CTask *task;
  CCtrl *c=native_window_control;
  Bool right=native_window_control_right,down;
  U32 bit=1;
  if(!c)return FALSE;
  task=NativeWindowFind(native_window_control_task);
  if(!task || !NativeWindowControlMember(task,c)) {
    native_window_control=NULL;native_window_control_task=0;return FALSE;
  }
  if(right)bit=2;
  down=(buttons&bit)!=0;
  //Capture outlives hit/inhibition changes, as in the original held-button loop.
  if(!down){native_window_control=NULL;native_window_control_task=0;}
  try {
    NativeRenderScopeOpen(&scope,&NativeWindowControlRelease);
    NativeRenderScopeBorrow(&scope,task,task,c);
    NativeWindowControlCall(task,c,x,y,right,down);
  } catch {NativeRenderScopeClose(&scope);}
  NativeRenderScopeClose(&scope);return TRUE;
}

I64 native_window_wheel_z;
U0 NativeWindowControlWheel()
{//Like WinMgrTask, retain inhibited deltas and use the first focused wheel control.
  CTask *task=sys_focus_task;
  CCtrl *c;
  CNativeRenderScope scope;
  if(!ms.has_wheel || native_window_wheel_z==ms.pos.z)return;
  if(!TaskValidate(task)){native_window_wheel_z=ms.pos.z;return;}
  if(NativeLegacyViewActive(task) || !NativeWindowControlEnabled(task) ||
      NativeWindowControlTarget(ms.pos.x,ms.pos.y)!=task)return;
  try {
    NativeRenderScopeOpen(&scope,&NativeWindowControlRelease);
    NativeRenderScopeBorrow(&scope,task,task,NULL);
    for(c=task->next_ctrl;c!=&task->next_ctrl;c=c->next) {
      if(c->wheel_chg) {
        native_window_fault_task=task->task_num;
        (*c->wheel_chg)(c,ms.pos.z-native_window_wheel_z);
        native_window_fault_task=0;
        break;
      }
    }
    native_window_wheel_z=ms.pos.z;
  } catch {NativeRenderScopeClose(&scope);}
  NativeRenderScopeClose(&scope);
}
