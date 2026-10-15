I64 DEState(I64 mode)
{
  CDoc *d=DocNew("State.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  I64 l=Fs->win_left,r=Fs->win_right,t=Fs->win_top,b=Fs->win_bottom;
  I64 attr=Fs->text_attr,title_src=Fs->title_src,flags=DOF_DONT_WINMGR_SYNC|DOF_DONT_SHOW,m=0;
  U8 *title=StrNew(Fs->task_title);
  Bool shown=Bt(&Fs->display_flags,DISPLAYf_SHOW),locked=mode==5,res,geometry;
  DocPrint(d,"First\nSecond\n");
  if(mode==2)flags|=DOF_WIN_MAX;
  if(mode==3)flags|=DOF_WIN_MAX|DOF_SIZE_MIN;
  if(mode==4)flags|=DOF_DONT_HOME|DOF_DONT_TEXT_ATTR;
  if(locked)DocLock(d);
  FlushMsgs;
  if(mode==1)Msg(MSG_KEY_DOWN,CH_SHIFT_ESC,0);
  else Msg(MSG_KEY_DOWN,CH_ESC,0);
  res=DocEd(d,flags);
  if(res==(mode!=1))m|=1;
  if(DocPut==put&&DocDisplay==display&&DocBorder==border)m|=2;
  if(Fs->text_attr==attr)m|=4;
  if(Fs->title_src==title_src&&!StrCmp(Fs->task_title,title))m|=8;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==locked)m|=16;
  geometry=Fs->win_left==l&&Fs->win_right==r&&Fs->win_top==t&&Fs->win_bottom==b;
  if(mode==2){
    if(Bt(&Fs->display_flags,DISPLAYf_NO_BORDER))
      geometry=Fs->win_left==0&&Fs->win_right==79&&Fs->win_top==1&&Fs->win_bottom==59;
    else geometry=Fs->win_left==1&&Fs->win_right==78&&Fs->win_top==2&&Fs->win_bottom==58;
  }
  if(geometry)m|=32;
  if(d->win_task==Fs&&d->parent_doc==display)m|=64;
  if(Bt(&Fs->display_flags,DISPLAYf_SHOW)==shown)m|=128;
  if(locked)DocUnlock(d);
  DocDel(d);Free(title);FlushMsgs;WinHorz(l,r);WinVert(t,b);
  return m;
}
