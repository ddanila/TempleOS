I64 DUClock()
{
  I64 i,a,b,last,flags=GetRFlags,m=0,start_j,end_j,freq=cnts.time_stamp_freq,delta,want;
  Bool monotonic=TRUE;
  if(freq>0&&cnts.time_stamp_freq_initial>0)m|=1;
  last=GetTSC;
  for(i=0;i<512;i++){b=GetTSC;if(b<last)monotonic=FALSE;last=b;}
  if(monotonic)m|=2;
  start_j=cnts.jiffies;a=GetTSC;Sleep(120);b=GetTSC;end_j=cnts.jiffies;
  delta=(b-a)*JIFFY_FREQ;want=(end_j-start_j)*freq;
  if(b>a&&want>0&&AbsI64(delta-want)<=want/5+freq*20)m|=4;
  if((GetRFlags&0x200)==(flags&0x200))m|=8;
  SetRFlags(flags&~0x200);a=GetTSC;last=a;monotonic=TRUE;
  for(i=0;i<2048;i++){b=GetTSC;if(b<last)monotonic=FALSE;last=b;}
  if(!(GetRFlags&0x200))m|=16;
  SetRFlags(flags);
  if(monotonic&&last>a)m|=32;
  return m;
}
Bool DULine(CDoc*d,U8*want)
{U8*s=DocScanLine(d,d->head.next);Bool r=s&&!StrCmp(s,want);Free(s);return r;}
I64 DUContract(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,t0,t1,extra=FALSE;
  CDoc *put=DocPut,*d=DocNew("Undo.DD");
  CDocUndo *u;
  Bool captured,gate=TRUE,locked=mode==5,record=TRUE,restored=TRUE;
  DocPrint(d,"AB");DocTop(d);d->flags|=DOCF_NO_CURSOR;
  if(mode)d->flags|=DOCF_ALLOW_UNDO;
  if(locked)DocLock(d);
  t0=GetTSC;captured=DocCaptureUndo(d,TRUE);t1=GetTSC;
  if(captured==(mode!=0)&&d->undo_cnt==(mode!=0))m|=1;
  if(mode){
    u=d->undo_head.last;
    record=u!=&d->undo_head&&u->time_stamp>=t0&&u->time_stamp<=t1&&u->body&&u->size>0&&
      u->doc_flags&DOCF_NO_CURSOR&&MHeapCtrl(u)->mem_task==d->mem_task;
    if(mode==3){u->time_stamp=GetTSC+cnts.time_stamp_freq*100;d->flags|=DOCF_UNDO_DIRTY;
      gate=!DocCaptureUndo(d)&&d->undo_cnt==1&&d->flags&DOCF_UNDO_DIRTY;}
    else gate=!DocCaptureUndo(d)&&d->undo_cnt==1;
    EdCharIns('X',0,d);
    if(mode==2||mode==4){
      if(mode==4){u->time_stamp=-cnts.time_stamp_freq*1024;d->flags|=DOCF_UNDO_DIRTY;}
      extra=DocCaptureUndo(d,mode==2);
      gate=gate&&extra&&d->undo_cnt==2&&!(d->flags&DOCF_UNDO_DIRTY);
      EdCharIns('Y',0,d);DocUndoRestore(d);
      restored=DULine(d,"XAB")&&d->undo_cnt==1&&EdCurU8(d)=='A';
    }
    DocUndoRestore(d);
  } else DocUndoRestore(d);
  if(record&&gate)m|=2;
  if(restored&&DULine(d,"AB")&&!d->undo_cnt&&d->undo_head.next==&d->undo_head&&
      d->undo_head.last==&d->undo_head&&EdCurU8(d)=='A')m|=4;
  if(d->flags&DOCF_NO_CURSOR&&!(d->flags&DOCF_UNDO_DIRTY)&&
      Bt(&d->locked_flags,DOClf_LOCKED)==locked&&(!locked||d->owning_task==Fs))m|=8;
  if(DocPut==put)m|=16;
  DocUnlock(d);DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=32;
  return m;
}
I64 DUCheck(I64 mode){I64 m=DUContract(mode);if(m!=63)throw('UndoCmp',TRUE);return m;}
