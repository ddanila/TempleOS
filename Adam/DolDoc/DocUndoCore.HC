Bool DocCaptureUndo(CDoc *doc,Bool force=FALSE)
{
  Bool res=FALSE,unlock;
  I64 time_stamp,flags;
  CDocUndo *u;
  if (doc->flags&DOCF_ALLOW_UNDO) {
    unlock=DocLock(doc);
    time_stamp=GetTSC;
    if (doc->flags&DOCF_UNDO_DIRTY &&
	  time_stamp>doc->undo_head.last->time_stamp+cnts.time_stamp_freq<<4 ||
	  force) {
      u=CAlloc(sizeof(CDocUndo),doc->mem_task);
      u->time_stamp=time_stamp;
      flags=doc->flags;
      doc->flags&=~DOCF_NO_CURSOR;
      u->body=DocSave(doc,&u->size);
      doc->flags=flags;
      QueIns(u,doc->undo_head.last);
      doc->flags&=~DOCF_UNDO_DIRTY;
      doc->undo_cnt++;
      u->doc_flags=doc->flags;
      res=TRUE;
      if (doc->flags&DOCF_AUTO_SAVE)
	DocWrite(doc);
    }
    if (unlock)
      DocUnlock(doc);
  }
  return res;
}
 
U0 DocUndoRestore(CDoc *doc)
{
  Bool unlock=DocLock(doc);
  CDocUndo *u=doc->undo_head.last,*u_next,*u_last;
  if (u!=&doc->undo_head) {
    QueRem(u);
    u_next=doc->undo_head.next;
    u_last=doc->undo_head.last;
    QueInit(&doc->undo_head);
    DocRst(doc,TRUE);
    doc->flags=u->doc_flags&~DOCF_NO_CURSOR;
    DocLoad(doc,u->body,u->size);
    doc->flags=u->doc_flags;
    DocUndoDel(doc,u);
    doc->undo_head.next=u_next;
    doc->undo_head.last=u_last;
  }
  DocUndoCntSet(doc);
  doc->flags&=~DOCF_UNDO_DIRTY;
  if (unlock)
    DocUnlock(doc);
}

