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
