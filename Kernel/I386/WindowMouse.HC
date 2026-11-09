//Original document actions and double-click rules, in the managed WinMgr task.
#include "/Adam/DolDoc/DocMouseActionCore.HC"
CMsStateGlbls native_window_mouse,native_window_mouse_old,native_window_mouse_last;
F64 native_window_mouse_time;
U32 native_window_mouse_buttons,native_window_mouse_losses;
CD3I64 native_window_mouse_single;
Bool native_window_mouse_resync;
#include "/Kernel/I386/WindowMouseControls.HC"
U0 NativeWindowMousePost(CTask *task,I64 code,I64 a,I64 b)
{NativePostMsg(task,code,a,b,0);}
#include "/Adam/WinQueIPMsgsCore.HC"
U0 NativeWindowMousePublish()
{
  ms.left_dbl_time=native_window_mouse.left_dbl_time;
  ms.right_dbl_time=native_window_mouse.right_dbl_time;
  ms.left_dbl=native_window_mouse.left_dbl;ms.right_dbl=native_window_mouse.right_dbl;
  ms.left_down_sent=native_window_mouse.left_down_sent;
  ms.right_down_sent=native_window_mouse.right_down_sent;
}
I64 NativeWindowMouseMessages(Bool que)
{
  I64 code=WinQueIPMsgsCore(&native_window_mouse,&native_window_mouse_old,
    &native_window_mouse_last,&native_window_mouse_single,native_window_mouse_time,
    que,&NativeWindowMousePost);
  NativeWindowMousePublish;return code;
}
U0 NativeWindowMousePosition(CNativeMousePosition *position)
{
  //These logical coordinates already include the original per-packet offset path.
  //Never reapply today's scale/offset to historical hardware coordinates.
  native_window_mouse.dbl_time=ms.dbl_time;
  MemCpy(&native_window_mouse.pos,&position->pos,sizeof(CD3I64));
  MemCpy(&native_window_mouse.presnap,&position->presnap,sizeof(CD3I64));
  native_window_mouse.pos_text.x=position->pos.x/FONT_WIDTH;
  native_window_mouse.pos_text.y=position->pos.y/FONT_HEIGHT;
}
class CNativeWindowMouseScope:CNativeRenderScope {
  CDoc *doc;
  Bool locked;
};
U0 NativeWindowMouseRelease(CNativeRenderScope *base)
{
  CNativeWindowMouseScope *scope=base;
  if(scope->locked) {scope->locked=FALSE;DocUnlock(scope->doc);}
}
CTask *NativeWindowMouseTarget(I64 x,I64 y)
{
  CTask *task=sys_winmgr_task->last_task;
  CDoc *doc;
  while(task!=sys_winmgr_task) {
    if(!TaskValidate(task))return NULL;
    if(!NativeRenderOwnerClosing(task) && Bt(&task->display_flags,DISPLAYf_SHOW) &&
        WinInside(x,y,task,FONT_WIDTH) && !NativeLegacyViewActive(task)) {
      doc=DocDisplay(task);
      if(task->next_ctrl!=&task->next_ctrl || task->draw_it ||
          doc && !(doc->flags&DOCF_DONT_SHOW) && NativeTerminalDocumentView(task,doc))return task;
    }
    task=task->last_task;
  }
  return NULL;
}
U0 NativeWindowMouseDocument(CTask *task,I64 x,I64 y,Bool right,Bool down,Bool dbl)
{
  CNativeWindowMouseScope scope;
  CDoc *doc=DocDisplay(task);
  I64 action=0;
  if(!doc || NativeLegacyViewActive(task))return;
  if(Bt(&task->win_inhibit,WIf_SELF_CTRLS)==FALSE &&
      (!TaskValidate(sys_focus_task) || !Bt(&sys_focus_task->win_inhibit,WIf_FOCUS_TASK_CTRLS))) {
    if(NativeWindowControlHit(task,x,y))return;
  }
  if(right) {
    if(Bt(&task->win_inhibit,WIf_SELF_MS_R) || TaskValidate(sys_focus_task) &&
        Bt(&sys_focus_task->win_inhibit,WIf_FOCUS_TASK_MS_R))return;
  } else if(Bt(&task->win_inhibit,WIf_SELF_MS_L) || TaskValidate(sys_focus_task) &&
      Bt(&sys_focus_task->win_inhibit,WIf_FOCUS_TASK_MS_L))return;
  scope.doc=doc;scope.locked=FALSE;
  try {
    NativeRenderScopeOpen(&scope,&NativeWindowMouseRelease);
    NativeRenderScopeBorrow(&scope,doc->mem_task,task,doc);
    if(WinCursorPosSet(task,x,y,down)!=doc)goto mouse_document_done;
    if(!TaskValidate(task) || DocDisplay(task)!=doc)goto mouse_document_done;
    DocLock(doc);scope.locked=TRUE;
    if(doc->doc_signature==DOC_SIGNATURE_VAL) {
      if(down)DocMousePressCore(doc,right);
      else action=DocMouseReleaseCore(doc,right,dbl);
    }
    NativeWindowMouseRelease(&scope);
    if(action)NativePostMsg(task,MSG_KEY_DOWN,action,0,0);
mouse_document_done:
    NativeWindowMouseRelease(&scope);
  } catch {
    NativeWindowMouseRelease(&scope);NativeRenderScopeClose(&scope);
  }
  NativeRenderScopeClose(&scope);
}
U0 NativeWindowMouseDispatch(I64 code,U32 previous,Bool documents=TRUE)
{
  CTask *task;
  I64 x=native_window_mouse.pos.x,y=native_window_mouse.pos.y;
  U32 buttons=native_window_mouse.lb+2*native_window_mouse.rb,owned=native_window_control_gestures;
  Bool consumed=NativeWindowControlCapture(x,y,buttons),hit;
  if(code==MSG_MS_L_UP || code==MSG_MS_L_D_UP)native_window_control_gestures&=~1;
  if(code==MSG_MS_R_UP || code==MSG_MS_R_D_UP)native_window_control_gestures&=~2;
  if(consumed)return;
  if(documents)task=NativeWindowMouseTarget(x,y);
  else task=NativeWindowControlTarget(x,y);
  if(!task)return;
  if((buttons^previous)&1) {
    if(buttons&1){native_window_control_gestures&=~1;owned&=~1;}
    hit=NativeWindowControlEdge(task,x,y,FALSE,(buttons&1)!=0);
    if(hit)owned|=1;
    else if(documents && buttons&1)NativeWindowMouseDocument(task,x,y,FALSE,TRUE,FALSE);
  }
  if((buttons^previous)&2 && !native_window_control) {
    if(buttons&2){native_window_control_gestures&=~2;owned&=~2;}
    hit=NativeWindowControlEdge(task,x,y,TRUE,(buttons&2)!=0);
    if(hit)owned|=2;
    else if(documents && buttons&2)NativeWindowMouseDocument(task,x,y,TRUE,TRUE,FALSE);
  }
  if(documents && !(owned&1) && (code==MSG_MS_L_UP || code==MSG_MS_L_D_UP))
    NativeWindowMouseDocument(task,x,y,FALSE,FALSE,code==MSG_MS_L_D_UP);
  if(documents && !(owned&2) && (code==MSG_MS_R_UP || code==MSG_MS_R_D_UP))
    NativeWindowMouseDocument(task,x,y,TRUE,FALSE,code==MSG_MS_R_D_UP);
}
U0 NativeWindowMouseReset()
{
  MemSet(&native_window_mouse,0,sizeof(CMsStateGlbls));
  MemSet(&native_window_mouse_old,0,sizeof(CMsStateGlbls));
  MemSet(&native_window_mouse_last,0,sizeof(CMsStateGlbls));
  native_window_mouse_buttons=0;NativeWindowControlReset;NativeWindowMousePublish;
}
U0 NativeWindowMouseCancel()
{NativeWindowMouseReset;native_window_mouse_resync=TRUE;}
Bool NativeWindowMouseQueueMessages()
{
  CTask *focus=sys_focus_task;
  if(TaskValidate(focus) && !Bt(&focus->win_inhibit,WIf_FOCUS_TASK_CTRLS)) {
    if(NativeWindowControlHit(focus,native_window_mouse.pos.x,native_window_mouse.pos.y))return FALSE;
  }
  return TRUE;
}
U0 NativeWindowMousePump()
{
  CI386MouseEvent event;
  CNativeMousePosition position;
  U32 previous;
  I64 code;
  Bool managed=NativeWindowNeeded(),admitted=managed || NativeWindowControlNeeded();
  if(native_window_mouse_losses!=native_mouse_events.losses) {
    native_window_mouse_losses=native_mouse_events.losses;NativeWindowMouseCancel;
    KernelLog("MOUSE input reset\n");
  }
  while(NativeMouseEventRead(&event,&position)) {
    if(!admitted){NativeWindowMouseReset;goto mouse_next_event;}
    if(native_window_mouse_resync) {
      if(event.buttons&3)goto mouse_next_event;
      native_window_mouse_resync=FALSE;NativeWindowMouseReset;
    }
    previous=native_window_mouse_buttons;
    NativeWindowMousePosition(&position);
    native_window_mouse.lb=(event.buttons&1)!=0;native_window_mouse.rb=(event.buttons&2)!=0;
    native_window_mouse_time=event.stamp/1193182.0;
    code=NativeWindowMouseMessages(managed && NativeWindowMouseQueueMessages);
    native_window_mouse_buttons=event.buttons;
    NativeWindowMouseDispatch(code,previous,managed);
mouse_next_event:;
  }
  if(admitted && native_window_control)
    NativeWindowControlCapture(native_window_mouse.pos.x,native_window_mouse.pos.y,native_window_mouse_buttons);
  if(admitted && (native_window_mouse.left_dbl_time || native_window_mouse.right_dbl_time)) {
    native_window_mouse_time=NativeTimeStamp/1193182.0;
    code=NativeWindowMouseMessages(managed && NativeWindowMouseQueueMessages);
    NativeWindowMouseDispatch(code,native_window_mouse_buttons,managed);
  }
}
