I64 WBCase(Bool initial,Bool enabled)
{
  I64 flags=GetRFlags,l=Fs->win_left,r=Fs->win_right;
  I64 t=Fs->win_top,b=Fs->win_bottom,ok=TRUE;
  Bool old=Bt(&Fs->display_flags,DISPLAYf_NO_BORDER);
  if(initial)Btr(&Fs->display_flags,DISPLAYf_NO_BORDER);
  else Bts(&Fs->display_flags,DISPLAYf_NO_BORDER);
  if(enabled)SetRFlags(flags|512);else SetRFlags(flags&~512);
  ok=WinBorder(!initial,Fs)==initial;
  ok=ok && ((GetRFlags>>9)&1)==enabled;
  ok=ok && Bt(&Fs->display_flags,DISPLAYf_NO_BORDER)==initial;
  I64 d=1;if(initial)d=-1;
  ok=ok && Fs->win_left==l+d && Fs->win_right==r-d;
  ok=ok && Fs->win_top==t+d && Fs->win_bottom==b-d;
  ok=ok && WinBorder(!initial)==!initial;
  ok=ok && Fs->win_left==l+d && Fs->win_right==r-d;
  ok=ok && Fs->win_top==t+d && Fs->win_bottom==b-d;
  ok=ok && WinBorder(initial)==!initial;
  ok=ok && Fs->win_left==l && Fs->win_right==r;
  ok=ok && Fs->win_top==t && Fs->win_bottom==b;
  ok=ok && ((GetRFlags>>9)&1)==enabled;
  SetRFlags(flags);
  if(old)Bts(&Fs->display_flags,DISPLAYf_NO_BORDER);
  else Btr(&Fs->display_flags,DISPLAYf_NO_BORDER);
  TaskDerivedValsUpdate(Fs,FALSE);
  return ok;
}
I64 WBInvalid()
{
  CTask *task=CAlloc(sizeof(CTask));
  I64 flags=GetRFlags,ok;
  task->win_left=7;task->win_right=19;
  task->win_top=11;task->win_bottom=23;
  ok=!WinBorder(ON,task) && !WinBorder(OFF,task);
  ok=ok && task->win_left==7 && task->win_right==19;
  ok=ok && task->win_top==11 && task->win_bottom==23;
  ok=ok && task->display_flags==0 && ((GetRFlags^flags)&512)==0;
  Free(task);return ok;
}
I64 WBContract()
{
  I64 mask=0;
  if(WBCase(FALSE,FALSE))mask|=1;
  if(WBCase(FALSE,TRUE))mask|=2;
  if(WBCase(TRUE,FALSE))mask|=4;
  if(WBCase(TRUE,TRUE))mask|=8;
  if(WBInvalid)mask|=16;
  return mask;
}
