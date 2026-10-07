Bool JobResScan(CJob *rqst=NULL,I64 *_res=NULL)
{//Check rqst complete, return with or without.
  I64 old_flags;
  CJobCtrl *ctrl;
  CJob *tmpc,*tmpc1;
  if (!rqst || Bt(&rqst->flags,JOBf_DONE)) {
    if (!rqst || rqst->master_task)
      ctrl=&Fs->srv_ctrl;
    else
      ctrl=rqst->ctrl;
    old_flags=GetRFlags;
    SetRFlags(old_flags&~512);
    while (LBts(&ctrl->flags,JOBCf_LOCKED))
      {}
    tmpc1=&ctrl->next_done;
    tmpc=tmpc1->next;
    while (tmpc!=tmpc1) {
      if (!rqst || rqst==tmpc) {
	QueRem(tmpc);
	LBtr(&ctrl->flags,JOBCf_LOCKED);
	SetRFlags(old_flags);
	if (_res)
	  *_res=tmpc->res;
	JobDel(tmpc);
	return TRUE;
      }
      tmpc=tmpc->next;
    }
    LBtr(&ctrl->flags,JOBCf_LOCKED);
    SetRFlags(old_flags);
  }
  if (_res)
    *_res=0;
  return FALSE;
}

