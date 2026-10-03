//Shared public job-queue initialization; callers declare CJob and CJobCtrl.
U0 JobCtrlInit(CJobCtrl *ctrl)
{
  ctrl->next_waiting=ctrl->last_waiting=&ctrl->next_waiting;
  ctrl->next_done=ctrl->last_done=&ctrl->next_done;
  ctrl->flags=0;
}
