U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
CCtrl *ad_ctrl;I64 ad_calls;Bool ad_context;
U0 ADUpdate(CCtrl *c)
{ad_calls++;ad_context=Fs==sys_winmgr_task&&Fs!=c->win_task;c->right=c->win_task->pix_width-2;}
U0 ADStart()
{
  ad_calls=0;ad_context=FALSE;ad_ctrl=CAlloc(sizeof(CCtrl));
  ad_ctrl->type=CTRLT_GENERIC;ad_ctrl->win_task=Fs;
  ad_ctrl->update_derived_vals=&ADUpdate;QueIns(ad_ctrl,Fs->last_ctrl);
}
I64 ADObserve()
{
  I64 m=0;
  if(ad_calls>0&&ad_context)m|=1;
  if(ad_ctrl->right==Fs->pix_width-2)m|=2;
  QueRem(ad_ctrl);Free(ad_ctrl);return m;
}
I64 *result=CAlloc(8);
ADStart;Sleep(250);*result=ADObserve;
U8 *message=MStrPrint("EXPORT auto-derived.bin %X %X\n",result,8);
Report(message);Free(message);
Report("DONE original automatic derived control\n");
