U0 MLObserve(U8 *)
{//Observe twenty completed updates with the default document refresh policy.
//No refresh flags, counters or cursor fields are changed by this observer.
  U8 *p,*s;I64 count,last=-1,frame,doc_frame,reported=-1;
  I64 wheel=ms.pos.z,wheel_frame=0,wheel_doc_frame=0,wheel_seen=0;
  Bool ready=FALSE,unlock;
  CDocEntry *e;
  LBtr(&Fs->display_flags,DISPLAYf_SHOW);
  while(!ml_done) {
    count=0;unlock=DocLock(ml_doc);
    if(ml_doc->flags&DOCF_DO_FULL_REFRESH)throw('MLPolicy',TRUE);
    for(e=ml_doc->head.next;e!=ml_doc;e=e->next) {
      if(e->type_u8==DOCT_TEXT&&e->tag) {
        if(!ready&&StrMatch("<ESC> to Exit",e->tag)){ready=TRUE;MLLog("ML READY\n");}
        p=e->tag;
        while(p=StrMatch("CMD:",p)){count++;p+=4;}
      }
    }
    if(count!=last) {
      last=ml_count=count;frame=winmgr.updates+20;doc_frame=ml_doc->updates_cnt+20;
      s=MStrPrint("ML COUNT %d\n",count);MLLog(s);Free(s);
    }
    if(ms.pos.z!=wheel) {
      wheel=ms.pos.z;wheel_seen++;
      wheel_frame=winmgr.updates+20;wheel_doc_frame=ml_doc->updates_cnt+20;
    }
    if(ready&&reported!=count&&winmgr.updates>=frame&&ml_doc->updates_cnt>=doc_frame) {
      reported=count;
      s=MStrPrint("ML FRAME %d\n",count);MLLog(s);Free(s);
      s=MStrPrint("ML STATE %d %d %d %d %d %X %X\n",count,winmgr.updates,
        ml_doc->updates_cnt,ml_doc->x,ml_doc->y,
        ml_owner->horz_scroll.flags,ml_owner->vert_scroll.flags);MLLog(s);Free(s);
    }
    if(wheel_seen&&winmgr.updates>=wheel_frame&&ml_doc->updates_cnt>=wheel_doc_frame) {
      wheel_seen=0;MLLog("ML WHEEL FRAME\n");
    }
    if(unlock)DocUnlock(ml_doc);
    Sleep(10);
  }
}
