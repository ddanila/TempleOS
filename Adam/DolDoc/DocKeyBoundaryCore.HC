//Original DocPutKey document-boundary movement; caller holds the document lock.
U0 DocKeyBoundaryCore(CDoc *doc,I64 sc,Bool end)
{
  CDocEntry *doc_ce=doc->cur_entry;
  if (end) {
    while (doc_ce!=doc) {
      BEqu(&doc_ce->type,DOCEt_SEL,sc&SCF_SHIFT);
      doc_ce=doc->cur_entry=doc_ce->next;
    }
    doc->cur_col=doc_ce->min_col;
    DocFormBwd(doc);
  } else {
    if (doc_ce==doc) doc_ce=doc_ce->last;
    while (doc_ce!=doc) {
      BEqu(&doc_ce->type,DOCEt_SEL,sc&SCF_SHIFT);
      doc_ce=doc->cur_entry=doc_ce->last;
    }
    doc_ce=doc->cur_entry=doc->head.next;
    doc->cur_col=doc_ce->min_col;
    DocFormFwd(doc);
  }
}
