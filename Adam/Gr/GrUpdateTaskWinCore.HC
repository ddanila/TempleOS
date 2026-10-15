U0 GrTaskWinRelease(CTask *task,CDC **dc,CD3I64 *scroll,Bool *saved)
{
  CDC *alias=*dc;
  *dc=NULL;DCDel(alias);
  if(*saved) {*saved=FALSE;WinScrollRestore(task,scroll);}
}
#ifndef GR_TASK_WIN_SCOPE_LOCAL
#define GR_TASK_WIN_SCOPE_LOCAL
#define GR_TASK_WIN_SCOPE_OPEN
#define GR_TASK_WIN_SCOPE_CLOSE
#endif
U0 GrUpdateTaskWinCore(CTask *task)
{
  CDC *dc=NULL;
  CD3I64 saved_scroll;
  Bool scroll_saved=FALSE;
  GR_TASK_WIN_SCOPE_LOCAL;
  try {
    GR_TASK_WIN_SCOPE_OPEN;
    if (!Bt(&task->display_flags,DISPLAYf_NO_BORDER))
      TextBorder(Fs,task->win_left,task->win_right,task->win_top,
	    task->win_bottom,task->border_attr,task==sys_focus_task);
    TextRect(task->win_left,task->win_right,
	  task->win_top,task->win_bottom,task->text_attr<<8);
    if (task==sys_winmgr_task) {
      if (gr.fp_wall_paper)
	(*gr.fp_wall_paper)(task);
    } else if (!(task->win_inhibit&WIF_SELF_DOC))
      DocUpdateTaskDocs(task);
    if (TaskValidate(task)) {
      if (task->draw_it) {
	dc=DCAlias(gr.dc2,task);
	(*task->draw_it)(task,dc);
	DCDel(dc);dc=NULL;
      }
      if (TaskValidate(task)) {
	WinScrollNull(task,&saved_scroll);scroll_saved=TRUE;
	DrawCtrls(task);
	scroll_saved=FALSE;WinScrollRestore(task,&saved_scroll);
      }
    }
    GrTaskWinRelease(task,&dc,&saved_scroll,&scroll_saved);
  } catch {
    GrTaskWinRelease(task,&dc,&saved_scroll,&scroll_saved);
    GR_TASK_WIN_SCOPE_CLOSE;
  }
  GR_TASK_WIN_SCOPE_CLOSE;
}
