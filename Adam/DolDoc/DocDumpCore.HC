U0 DocDump(CDoc *doc,I64 uS_delay=0)
{
  U8 *st;
  CDocEntry *doc_e,*doc_e2;
  Bool unlock=DocLock(doc);
  doc_e=doc->head.next;
  while (doc_e!=doc) {
    st=DocScanLine(doc,doc_e,NULL,&doc_e2);
    "%s",st;
    Free(st);
    doc_e=doc_e2;
    if (doc_e->type_u8==DOCT_NEW_LINE) {
      '\n';
      Busy(uS_delay);
      doc_e=doc_e->next;
    }
  }
  if (unlock)
    DocUnlock(doc);
}
