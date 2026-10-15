I64 WMCase(Bool border)
{
  I64 l=Fs->win_left,r=Fs->win_right,t=Fs->win_top,b=Fs->win_bottom;
  Bool old=Bt(&Fs->display_flags,DISPLAYf_NO_BORDER),ok;
  if(border) Btr(&Fs->display_flags,DISPLAYf_NO_BORDER);
  else Bts(&Fs->display_flags,DISPLAYf_NO_BORDER);
  WinMax;
  if(border)ok=Fs->win_left==1&&Fs->win_right==78&&Fs->win_top==2&&Fs->win_bottom==58;
  else ok=Fs->win_left==0&&Fs->win_right==79&&Fs->win_top==1&&Fs->win_bottom==59;
  if(old)Bts(&Fs->display_flags,DISPLAYf_NO_BORDER);
  else Btr(&Fs->display_flags,DISPLAYf_NO_BORDER);
  WinHorz(l,r);WinVert(t,b);
  return ok;
}
I64 WMInterrupts(Bool enabled)
{
  I64 flags=GetRFlags,after;
  if(enabled)SetRFlags(flags|512);else SetRFlags(flags&~512);
  WinMax(Fs);
  after=GetRFlags;SetRFlags(flags);
  return ((after>>9)&1)==enabled;
}
I64 WMInvalid()
{
  CTask *t=CAlloc(sizeof(CTask));
  I64 flags=GetRFlags,ok;
  t->win_left=7;t->win_right=19;t->win_top=11;t->win_bottom=23;
  WinMax(t);
  ok=t->win_left==7&&t->win_right==19&&t->win_top==11&&t->win_bottom==23;
  ok=ok&&((GetRFlags^flags)&512)==0;
  Free(t);return ok;
}
