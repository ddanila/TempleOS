U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 ct_l,ct_r,ct_t,ct_b;
Bool ct_throw,ct_called;
CDC *ct_alias;
U0 CTDraw(CDC *dc,CCtrl *c)
{
  ct_alias=dc;
  ct_called=dc->win_task==Fs && Fs->win_left==ct_l-1 &&
    Fs->win_right==ct_r+1 && Fs->win_top==ct_t-1 && Fs->win_bottom==ct_b+1;
  if(ct_throw)throw('CtlFail',TRUE);
}
I64 CTContract(Bool fail)
{
  I64 before=Fs->data_heap->used_u8s,base,m=0,display=Fs->display_flags;
  CCtrl *old_next=Fs->next_ctrl,*old_last=Fs->last_ctrl,
    *head=&Fs->next_ctrl,*c=CAlloc(sizeof(CCtrl));
  Bool caught=FALSE;
  ct_l=Fs->win_left;ct_r=Fs->win_right;ct_t=Fs->win_top;ct_b=Fs->win_bottom;
  ct_throw=fail;ct_called=FALSE;ct_alias=NULL;
  LBtr(&Fs->display_flags,DISPLAYf_NO_BORDER);
  c->flags=CTRLF_SHOW|CTRLF_BORDER;c->draw_it=&CTDraw;c->win_task=Fs;
  c->next=c->last=head;Fs->next_ctrl=Fs->last_ctrl=c;
  base=Fs->data_heap->used_u8s;
  try {DrawCtrls(Fs);}
  catch {if(Fs->except_ch=='CtlFail'){caught=TRUE;Fs->catch_except=TRUE;}}
  if(ct_called)m|=1;
  if(Fs->win_left==ct_l && Fs->win_right==ct_r && Fs->win_top==ct_t &&
     Fs->win_bottom==ct_b && !Bt(&Fs->task_flags,TASKf_TASK_LOCK))m|=2;
  if(Fs->data_heap->used_u8s==base)m|=4;
  if(caught==fail)m|=8;
  //Old-reference fallback cleanup follows the observations, never their oracle.
  if(!(m&4))DCDel(ct_alias);
  Fs->win_left=ct_l;Fs->win_right=ct_r;Fs->win_top=ct_t;Fs->win_bottom=ct_b;
  WinDerivedValsUpdate(Fs);
  Fs->next_ctrl=old_next;Fs->last_ctrl=old_last;Fs->display_flags=display;
  Free(c);
  if(Fs->data_heap->used_u8s==before)m|=16;
  return m;
}
I64 *ct_result=CAlloc(16);
ct_result[0]=CTContract(FALSE);ct_result[1]=CTContract(TRUE);
U8 *ct_report=MStrPrint("EXPORT control-draw.bin %X %X\n",ct_result,16);
Report(ct_report);Free(ct_report);
Report("DONE control draw recovery\n");
