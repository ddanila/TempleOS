U0 Report(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool mc_unlocked;
I64 MCLeft(CDoc *d,CDocEntry *e)
{mc_unlocked=!Bt(&d->locked_flags,DOClf_LOCKED);return 17;}
I64 MCChoose(I64 mode)
{
  CDoc *d=DocNew("Chooser.DD"),*old_put=DocPut,*old_display=DocDisplay;
  U8 *old_end=Fs->task_end_cb;
  I64 old_border=Fs->border_src,r,a,b;
  Bool old_break=Bt(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC),state;
  CDocEntry *first=DocPrint(d,"$$MU,\"One\",LE=11,RE=12$$\n");
  DocPrint(d,"$$MU,\"Two\",LE=22,RE=23$$\n");
  d->flags|=DOCF_FORM;
  FlushMsgs;
  if(mode==4){first->de_flags=DOCEF_ESC|DOCEF_LEFT_CB|DOCEF_TAG;first->left_cb=&MCLeft;}
  if(mode==2)Msg(MSG_KEY_DOWN,0,SC_CURSOR_DOWN);
  if(mode==5)Msg(MSG_KEY_DOWN,'\t',SC_TAB);
  if(mode==6)Msg(MSG_KEY_DOWN,'\t',SC_TAB|SCF_SHIFT);
  if(mode==7)Msg(MSG_KEY_UP,0,SC_CURSOR_DOWN);
  if(mode==1)Msg(MSG_KEY_DOWN,10,0);
  else if(mode==3)Msg(MSG_KEY_DOWN,CH_SHIFT_ESC,0);
  else Msg(MSG_KEY_DOWN,32,0);
  Report("MENU begin\n");r=DocMenu(d);Report("MENU end\n");
  state=DocPut==old_put&&DocDisplay==old_display&&Fs->task_end_cb==old_end&&
    Fs->border_src==old_border&&Bt(&Fs->task_flags,TASKf_BREAK_TO_SHIFT_ESC)==old_break&&
    !Bt(&d->locked_flags,DOClf_LOCKED);
  if(mode!=3)state=state&&ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==r&&b==0;
  DocDel(d);FlushMsgs;
  if(!state)return -99;
  return r;
}
