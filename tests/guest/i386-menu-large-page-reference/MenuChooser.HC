U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 MCLarge(I64 mode)
{
  CDoc *d=DocNew("LargeChooser.DD"),*old_put=DocPut,*old_display=DocDisplay;
  U8 *old_end=Fs->task_end_cb;
  I64 old_border=Fs->border_src,old_top=Fs->win_top,old_bottom=Fs->win_bottom,i,r,a,b;
  Bool old_break=Bt(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC),state;
  for(i=0;i<72;i++)DocPrint(d,"$$MU,\"Item %02d\",LE=%d$$\n",i+1,i+1);
  WinVert(2,58,Fs);
  d->flags|=DOCF_FORM;
  FlushMsgs;
  if(mode==3)Msg(MSG_KEY_DOWN,0,SC_END);
  if(mode==0||mode==1||mode==2||mode==5)Msg(MSG_KEY_DOWN,0,SC_PAGE_DOWN);
  if(mode==1)Msg(MSG_KEY_DOWN,0,SC_PAGE_DOWN);
  if(mode==2||mode==3)Msg(MSG_KEY_DOWN,0,SC_PAGE_UP);
  if(mode==4)Msg(MSG_KEY_DOWN,0,SC_PAGE_DOWN|SCF_CTRL);
  if(mode==5)Msg(MSG_KEY_DOWN,0,SC_PAGE_DOWN|SCF_CTRL);
  Msg(MSG_KEY_DOWN,32,0);
  Report("LARGE MENU begin\n");r=DocMenu(d);Report("LARGE MENU end\n");
  state=DocPut==old_put&&DocDisplay==old_display&&Fs->task_end_cb==old_end&&
    Fs->border_src==old_border&&Bt(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC)==old_break&&
    !Bt(&d->locked_flags,DOClf_LOCKED)&&ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==r&&b==0;
  DocDel(d);FlushMsgs;
  WinVert(old_top,old_bottom,Fs);
  state=state&&Fs->win_top==old_top&&Fs->win_bottom==old_bottom;
  if(!state)return -99;
  return r;
}
