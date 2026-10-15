//Original control order and border clipping, with portable lock operations.
U0 DrawCtrlsGeometry(CTask *task,I64 expand)
{
  I64 flags=GetRFlags;
  SetRFlags(flags&~0x200);
  while(LBts(&task->task_flags,TASKf_TASK_LOCK)) {}
  task->win_left-=expand;task->win_right+=expand;
  task->win_top-=expand;task->win_bottom+=expand;
  WinDerivedValsUpdate(task);
  LBtr(&task->task_flags,TASKf_TASK_LOCK);
  SetRFlags(flags);
}
U0 DrawCtrlsRelease(CTask *task,CDC **dc,Bool *expanded)
{
  CDC *alias=*dc;
  *dc=NULL;
  if(*expanded) {*expanded=FALSE;DrawCtrlsGeometry(task,-1);}
  DCDel(alias);
}
#ifndef DRAW_CTRLS_SCOPE_LOCAL
#define DRAW_CTRLS_SCOPE_LOCAL
#define DRAW_CTRLS_SCOPE_OPEN
#define DRAW_CTRLS_SCOPE_CLOSE
#endif
U0 DrawCtrls(CTask *task)
{
  CCtrl *c;
  CDC *dc=NULL;
  Bool expanded=FALSE;
  DRAW_CTRLS_SCOPE_LOCAL;
  try {
    DRAW_CTRLS_SCOPE_OPEN;
    dc=DCAlias(gr.dc2,task);
    c=task->next_ctrl;
    while(c!=&task->next_ctrl) {
      if(c->flags&CTRLF_SHOW) {
        if(c->flags&CTRLF_BORDER) {
          if(!Bt(&task->display_flags,DISPLAYf_NO_BORDER)) {
            DrawCtrlsGeometry(task,1);expanded=TRUE;
            if(c->draw_it)(*c->draw_it)(dc,c);
            expanded=FALSE;DrawCtrlsGeometry(task,-1);
          }
        } else if(c->draw_it)(*c->draw_it)(dc,c);
      }
      c=c->next;
    }
    DrawCtrlsRelease(task,&dc,&expanded);
  } catch {
    DrawCtrlsRelease(task,&dc,&expanded);
    DRAW_CTRLS_SCOPE_CLOSE;
  }
  DRAW_CTRLS_SCOPE_CLOSE;
}
