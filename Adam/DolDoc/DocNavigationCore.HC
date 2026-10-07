public U0 DocTop(CDoc *doc=NULL)
{//Move cursor, cur_entry, to top.
  Bool unlock;
  if (!doc && !(doc=DocPut))
    return;
  unlock=DocLock(doc);
  doc->cur_entry=doc->head.next;
  doc->cur_col=doc->cur_entry->min_col;
  doc->x=0;
  doc->y=0;
  doc->line_start_col=0;
  doc->top_line_num=0;

  DocFormFwd(doc);
  DocRecalc(doc);
  if (unlock)
    DocUnlock(doc);
}

public U0 DocCenter(CDoc *doc=NULL,I64 recalc_flags=RECALCt_NORMAL)
{//Center win on doc cursor, cur_entry.
  Bool unlock;
  CTask *task;
  if (!doc && !(doc=DocPut))
    return;
  unlock=DocLock(doc);
  task=doc->win_task;
  DocRecalc(doc,recalc_flags);
  if (!(doc->flags&DOCF_BORDER_DOC))
    doc->top_line_num=doc->y-(task->win_height+1)>>1;
  if (unlock)
    DocUnlock(doc);
}

public U0 DocBottom(CDoc *doc=NULL)
{//Move cursor, cur_entry, to bottom.
  Bool unlock;
  if (!doc && !(doc=DocPut))
    return;
  unlock=DocLock(doc);
  doc->cur_entry=doc;
  doc->cur_col=0;
  DocRecalc(doc);
  if (unlock)
    DocUnlock(doc);
}

