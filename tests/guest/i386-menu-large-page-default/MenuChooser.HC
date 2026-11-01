U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 MCLarge(I64 mode)
{
  CDoc *d=DocNew("LargeChooser.DD"),*old_put=DocPut,*old_display=DocDisplay;
  U8 *old_end=Fs->task_end_cb;
  I64 old_border=Fs->border_src,i,r,a,b;
  Bool old_break=Bt(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC),state;
  for(i=0;i<72;i++)DocPrint(d,"$$MU,\"Item %02d\",LE=%d$$\n",i+1,i+1);
  U8 *geom=MStrPrint("LARGE GEOMETRY %d %d %d %d %d %d %X\n",Fs->win_left,Fs->win_right,Fs->win_top,Fs->win_bottom,Fs->win_width,Fs->win_height,Fs->display_flags);Report(geom);Free(geom);
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
  U8 *result_line=MStrPrint("LARGE RESULT %d %d\n",mode,r);Report(result_line);Free(result_line);
  state=DocPut==old_put&&DocDisplay==old_display&&Fs->task_end_cb==old_end&&
    Fs->border_src==old_border&&Bt(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC)==old_break&&
    !Bt(&d->locked_flags,DOClf_LOCKED)&&ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==r&&b==0;
  DocDel(d);FlushMsgs;
  if(!state)return -99;
  return r;
}

I64 MCWindow()
{
  return Fs->win_left==1&&Fs->win_right==39&&Fs->win_top==2&&Fs->win_bottom==58&&
    Fs->win_width==39&&Fs->win_height==57&&Fs->pix_left==8&&Fs->pix_top==16&&
    Fs->pix_width==312&&Fs->pix_height==456&&
    Bt(&Fs->display_flags,DISPLAYf_SHOW)&&Bt(&Fs->display_flags,DISPLAYf_NOT_RAW)&&
    !Bt(&Fs->display_flags,DISPLAYf_NO_BORDER);
}
