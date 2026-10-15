Bool dr_armed,dr_seen;
I64 dr_axis,dr_left,dr_top;
CDoc *dr_put;
U0 DRControl(CCtrl *c)
{
  CTask *t=c->win_task;
  if(dr_armed&&t==Fs&&DocPut==dr_put&&
      (dr_axis==0&&t->win_left==dr_left || dr_axis==1&&t->win_top==dr_top)) {
    dr_armed=FALSE;dr_seen=TRUE;throw('Restore',TRUE);
  }
}
I64 DRRestore(I64 axis)
{
  CDoc *d=DocNew("Restore.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CCtrl *c=CAlloc(sizeof(CCtrl));
  I64 l=Fs->win_left,r=Fs->win_right,t=Fs->win_top,b=Fs->win_bottom;
  I64 attr=Fs->text_attr,src=Fs->title_src,irq=GetRFlags,before,m=0;
  U8 *title=StrNew(Fs->task_title);
  Bool caught=FALSE;
  WinHorz(2,31);WinVert(3,20);
  c->win_task=Fs;c->type=CTRLT_GENERIC;c->update_derived_vals=&DRControl;
  QueIns(c,Fs->last_ctrl);
  dr_axis=axis;dr_left=2;dr_top=3;dr_put=put;dr_seen=FALSE;dr_armed=TRUE;
  before=Fs->data_heap->used_u8s;
  FlushMsgs;Msg(MSG_KEY_DOWN,CH_ESC,0);
  try{DocEd(d,DOF_WIN_MAX|DOF_SIZE_MIN|DOF_DONT_SHOW|DOF_DONT_WINMGR_SYNC);}
  catch{caught=Fs->except_ch=='Restore';Fs->catch_except=TRUE;}
  dr_armed=FALSE;
  if(caught)m|=1;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=2;
  if(Fs->text_attr==attr&&Fs->title_src==src&&!StrCmp(Fs->task_title,title))m|=4;
  if(!Bt(&d->locked_flags,DOClf_LOCKED)&&!d->owning_task)m|=8;
  if(Fs->data_heap->used_u8s==before)m|=16;
  if((GetRFlags&0x200)==(irq&0x200)&&!Bt(&Fs->task_flags,TASKf_TASK_LOCK))m|=32;
  if(dr_seen)m|=64;
  if(Fs->win_left==2&&Fs->win_right==31&&Fs->win_top==3&&Fs->win_bottom==20)m|=128;
  QueRem(c);Free(c);DocDel(d);Free(title);FlushMsgs;WinHorz(l,r);WinVert(t,b);
  return m;
}
