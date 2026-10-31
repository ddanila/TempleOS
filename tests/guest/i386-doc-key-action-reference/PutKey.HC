I64 ka_calls,ka_value;Bool ka_unlocked;
I64 KALeft(CDoc *doc,CDocEntry *entry)
{ka_calls++;ka_unlocked=!Bt(&doc->locked_flags,DOClf_LOCKED);return 17;}
I64 KARight(CDoc *doc,CDocEntry *entry)
{ka_calls++;ka_unlocked=!Bt(&doc->locked_flags,DOClf_LOCKED);return 18;}
I64 PKContract(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,ch=CH_SPACE,sc=0,a=0,b=0,msg,want=0;
  CDoc *old_put=DocPut,*old_display=DocDisplay,*d=DocNew("KeyAction.DD");
  CDocEntry *e=DocPrint(d,"$$TX,\"Action\"$$");
  Bool callback=FALSE,collapsed=FALSE;
  e->de_flags=DOCEF_TAG;d->cur_entry=e;d->cur_col=e->min_col;
  ka_calls=0;ka_unlocked=FALSE;
  switch(mode) {
    case 0:e->de_flags|=DOCEF_LEFT_EXP;e->left_exp=11;want=11;break;
    case 1:e->de_flags|=DOCEF_RIGHT_EXP;e->right_exp=12;ch='\n';want=12;break;
    case 2:e->de_flags|=DOCEF_LEFT_EXP;e->left_exp=11;sc=SCF_SHIFT;break;
    case 3:e->de_flags|=DOCEF_LEFT_EXP;e->left_exp=11;sc=SCF_CTRL;break;
    case 4:e->de_flags|=DOCEF_LEFT_CB;e->left_cb=&KALeft;want=17;callback=TRUE;break;
    case 5:e->de_flags|=DOCEF_RIGHT_CB;e->right_cb=&KARight;ch='\n';want=18;callback=TRUE;break;
    case 6:e->de_flags|=DOCEF_CHECK_COLLAPSABLE;collapsed=TRUE;break;
  }
  FlushMsgs;DocPutKey(d,ch,sc);msg=ScanMsg(&a,&b,1<<MSG_CMD);
  if(want && msg==MSG_CMD && a==want && !b || !want && !msg)m|=1;
  if(callback && ka_calls==1 && ka_unlocked || !callback && !ka_calls)m|=2;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=4;
  if(d->cmd_U8==CH_SPACE)m|=8;
  if(!collapsed || (e->de_flags&DOCEF_CHECKED_COLLAPSED)!=0)m|=16;
  if(DocPut==old_put && DocDisplay==old_display)m|=32;
  DocDel(d);FlushMsgs;
  if(Fs->data_heap->used_u8s==before)m|=64;
  return m;
}
I64 PKCheck(I64 mode){I64 m=PKContract(mode);if(m!=127)throw('KeyAct',TRUE);return m;}
