U0 DocMenuEndTaskCB()
{
  WinToTop;
  throw;
}

public I64 DocMenu(CDoc *m,I64 dof_flags=0)
{//Run menu chooser doc. Returns menu doc unlocked.
  U8 *old_end_cb=Fs->task_end_cb;
  Bool old_break_shift_esc=LBts(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC);
  CDocEntry *doc_e;
  I64 old_border_src=Fs->border_src,res=DOCM_CANCEL,has_action;
  Fs->task_end_cb=&DocMenuEndTaskCB;
  try {
    if (m) {
      m->desc='Menu';
      Fs->border_src=BDS_CONST;
dm_restart:
      if (DocEd(m,dof_flags)) {
	doc_e=m->cur_entry;
	if (doc_e!=m) {
	  res=DocEntryRun(m,doc_e,TRUE,&has_action);
	  DocUnlock(m);
	  if (!has_action) {
	    res=DOCM_CANCEL;
	    dof_flags|=DOF_DONT_HOME;
	    goto dm_restart;
	  }
	}
      }
    }
  } catch {
    if (!Fs->except_ch) {
      if (!(dof_flags & DOF_INTERCEPT_TASK_END))
	Exit;
      Fs->catch_except=TRUE;
    }
  }
  LBEqu(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC,old_break_shift_esc);
  Fs->border_src=old_border_src;
  Fs->task_end_cb=old_end_cb;
  return res;
}

