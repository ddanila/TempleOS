Bool da_unlocked;
I64 DALeft(CDoc *d,CDocEntry *e){da_unlocked=!Bt(&d->locked_flags,DOClf_LOCKED);return 17;}
I64 DARight(CDoc *d,CDocEntry *e){da_unlocked=!Bt(&d->locked_flags,DOClf_LOCKED);return 18;}
I64 DAAction(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,res,has=-1,a=0,b=0,msg,m=0;
  CDoc *d=DocNew("Action.DD");
  CDocEntry *e=DocPrint(d,"$$TX,\"Action\"$$");
  Bool exited=TRUE,want_action=TRUE,want_lock=TRUE;
  I64 want=DOCM_CANCEL,want_msg=0,want_a=0;
  da_unlocked=FALSE;e->de_flags=DOCEF_TAG;d->cmd_U8=CH_SPACE;
  switch(mode) {
    case 0:e->de_flags|=DOCEF_LEFT_EXP;e->left_exp=11;want=11;break;
    case 1:e->de_flags|=DOCEF_RIGHT_EXP;e->right_exp=12;d->cmd_U8=10;want=12;break;
    case 2:e->de_flags|=DOCEF_LEFT_CB;e->left_cb=&DALeft;want=17;want_lock=FALSE;break;
    case 3:e->de_flags|=DOCEF_RIGHT_CB;e->right_cb=&DARight;d->cmd_U8=10;want=18;want_lock=FALSE;break;
    case 4:want_action=FALSE;break;
    case 5:e->de_flags|=DOCEF_CHECK_COLLAPSABLE;exited=FALSE;break;
    case 6:e->de_flags|=DOCEF_ESC;exited=FALSE;want_msg=MSG_KEY_DOWN;want_a=CH_ESC;break;
    case 7:e->de_flags|=DOCEF_QUIT;exited=FALSE;want_msg=MSG_KEY_DOWN;want_a=CH_SHIFT_ESC;break;
  }
  if(mode<4){want_msg=MSG_CMD;want_a=want;}
  FlushMsgs;res=DocEntryRun(d,e,exited,&has);
  if(res==want)m|=1;
  if(has==want_action&&(mode!=5||e->de_flags&DOCEF_CHECKED_COLLAPSED))m|=2;
  msg=ScanMsg(&a,&b,1<<MSG_CMD|1<<MSG_KEY_DOWN);
  if(msg==want_msg&&(!msg||a==want_a&&!b))m|=4;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==want_lock&&(mode!=2&&mode!=3||da_unlocked))m|=8;
  if(d->cmd_U8==CH_SPACE)m|=16;
  DocUnlock(d);DocDel(d);FlushMsgs;
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
