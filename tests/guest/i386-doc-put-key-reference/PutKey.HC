I64 pk_calls,pk_ch,pk_sc;
Bool pk_consume,pk_unlocked,pk_data;
Bool PKHook(CDoc*d,U8*data,I64 ch,I64 sc)
{
  pk_calls++;pk_ch=ch;pk_sc=sc;
  pk_unlocked=!Bt(&d->locked_flags,DOClf_LOCKED);
  pk_data=data==d;
  return pk_consume;
}
Bool PKLine(CDoc*d,U8*want)
{U8*s=DocScanLine(d,d->head.next);Bool r=s&&!StrCmp(s,want);Free(s);return r;}
I64 PKContract(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0;
  CDoc *old_put=Fs->put_doc,*old_display=DocDisplay,*d=DocNew("PutKey.DD");
  Bool hook_ok=TRUE,action_ok=TRUE;
  DocPrint(d,"AB");DocTop(d);d->flags|=DOCF_DONT_SWAP_OUT;
  pk_calls=0;pk_consume=mode==0;pk_unlocked=FALSE;pk_data=FALSE;
  if(mode<2){d->user_put_key=&PKHook;d->user_put_data=d;}
  if(mode==2)Fs->put_doc=d;
  if(mode==4){DocPutKey(d,0,SC_INS);action_ok=d->flags&DOCF_OVERSTRIKE;}
  if(mode==5){d->flags|=DOCF_ALLOW_UNDO;DocCaptureUndo(d,TRUE);}
  if(mode==2)DocPutKey(NULL,'X',0);else DocPutKey(d,'X',0);
  if(mode<2)hook_ok=pk_calls==1&&pk_ch=='X'&&!pk_sc&&pk_unlocked&&pk_data;
  else hook_ok=!pk_calls;
  if(hook_ok)m|=1;
  if(mode==5){action_ok=d->undo_cnt==1;DocPutKey(d,CH_BACKSPACE,SCF_ALT|SC_BACKSPACE);action_ok=action_ok&&!d->undo_cnt;}
  if(action_ok)m|=2;
  if((mode==0||mode==5)&&PKLine(d,"AB")||mode==4&&PKLine(d,"XB")||
     (mode==1||mode==2||mode==3)&&PKLine(d,"XAB"))m|=4;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=8;
  if(Fs->put_doc==old_put&&mode!=2||mode==2&&Fs->put_doc==d)
    if(DocDisplay==old_display)m|=16;
  Fs->put_doc=old_put;DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
I64 PKCheck(I64 mode){I64 m=PKContract(mode);if(m!=63)throw('PutKey',TRUE);return m;}
