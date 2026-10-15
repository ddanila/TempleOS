public U0 DocCollapse(Bool collapse=TRUE,CDoc *doc=NULL)
{//Collapse or uncollapse all tree widgets.
  CDocEntry *doc_e;
  Bool unlock;
  if (!doc && !(doc=DocPut))
    return;
  unlock=DocLock(doc);
  doc_e=doc->head.next;
  while (doc_e!=doc) {
    if (doc_e->de_flags&DOCEF_TREE)
      BEqu(&doc_e->de_flags,DOCEf_CHECKED_COLLAPSED,collapse);
    doc_e=doc_e->next;
  }
  DocRecalc(doc);
  if (unlock)
    DocUnlock(doc);
}

