Bool ea_unlocked;
I64 EALeft(CDoc *d,CDocEntry *e){ea_unlocked=!Bt(&d->locked_flags,DOClf_LOCKED);return 17;}
I64 EARight(CDoc *d,CDocEntry *e){ea_unlocked=!Bt(&d->locked_flags,DOClf_LOCKED);return -3;}
I64 DollarParserContract()
{
  I64 mask=0,res,a,b;
  Bool action;
  CDoc *d=DocNew("C:/Actions.DD",Fs);
  CDocEntry *e=DocPrint(d,"$$BT,\"PLAY\",LE=2,RE=3$$"),*plain;
  d->cmd_U8=CH_SPACE;res=DocEntryRun(d,e,TRUE,&action);
  if(res==2&&action&&d->cmd_U8==CH_SPACE)mask|=1;
  if(ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==2&&b==0)mask|=2;
  DocUnlock(d);
  d->cmd_U8='\n';res=DocEntryRun(d,e,TRUE,&action);
  if(res==3&&action&&d->cmd_U8==CH_SPACE&&ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==3)mask|=4;
  DocUnlock(d);
  e->de_flags=DOCEF_LEFT_CB;e->left_cb=&EALeft;ea_unlocked=FALSE;
  d->cmd_U8=CH_SPACE;res=DocEntryRun(d,e,TRUE,&action);
  if(res==17&&action&&ea_unlocked&&ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==17)mask|=8;
  e->de_flags=DOCEF_RIGHT_CB;e->right_cb=&EARight;ea_unlocked=FALSE;
  d->cmd_U8='\n';res=DocEntryRun(d,e,TRUE,&action);
  if(res==-3&&action&&ea_unlocked&&ScanMsg(&a,&b,1<<MSG_CMD)==MSG_CMD&&a==-3)mask|=16;
  e->de_flags=0;d->cmd_U8=CH_SPACE;res=DocEntryRun(d,e,TRUE,&action);
  if(res==DOCM_CANCEL&&!action&&d->cmd_U8==CH_SPACE)mask|=32;
  DocUnlock(d);DocDel(d);
  return mask;
}
