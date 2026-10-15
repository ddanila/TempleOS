#ifndef DOC_ED_STATE_CORE_INCLUDED
#define DOC_ED_STATE_CORE_INCLUDED
class CDocEdState {
  CTask *task,*old_doc_win_task;
  I64 old_doc_win_num;
  CDoc *doc,*old_put_doc,*old_display_doc,*old_border_doc,*bdoc;
  I64 old_attr,old_top,old_bottom,old_left,old_right,old_title_src,dof_flags;
  U8 *old_task_title;
  Bool unlock,lock_saved,released;
};
U0 DocEdStateRestore(CDocEdState *state)
{
  CDoc *border;
  U8 *title;
  if(state->released)return;
  state->released=TRUE;
  if(state->lock_saved) {
    if(state->unlock)DocUnlock(state->doc);
    else DocLock(state->doc);
  }
  state->task->border_doc=state->old_border_doc;
  state->task->display_doc=state->old_display_doc;
  state->task->put_doc=state->old_put_doc;
  state->task->text_attr=state->old_attr;
  title=state->old_task_title;state->old_task_title=NULL;
  if(title && state->task->title_src!=TTS_LOCKED_CONST) {
    state->task->title_src=state->old_title_src;
    StrCpy(state->task->task_title,title);
  }
  border=state->bdoc;state->bdoc=NULL;
  Free(title);DocDel(border);
  if(state->dof_flags&DOF_SIZE_MIN) {
    WinHorz(state->old_left,state->old_right,state->task);
    WinVert(state->old_top,state->old_bottom,state->task);
  }
}

#endif
