public U0 DocInsDoc(CDoc *doc=NULL,CDoc *doc2)
{//Insert copy of doc2 into doc at insert pt, cur_entry.
//TODO: $LK,"DocRst",A="MN:DocRst"$
  U8 *dst;
  Bool unlock_doc,unlock_doc2=DocLock(doc2);
  CDocEntry *doc_ne,*doc_e=doc2->head.next,*doc_ce;
  if (!doc) doc=DocPut;
  unlock_doc=DocLock(doc),
	DocRemSoftNewLines(doc,NULL);
  doc_ce=doc->cur_entry;
  if (doc_ce->type_u8==DOCT_TEXT && doc->cur_col>doc_ce->min_col) {
    if (doc->cur_col<doc_ce->max_col) {
      dst=doc_ce->tag+doc->cur_col;
      doc_ne=DocEntryNewTag(doc,doc_ce,dst);
      *dst=0;
      doc_ne->type=DOCT_TEXT | doc_ce->type & 0xFFFFFF00;
      doc_ce->max_col=doc->cur_col;
      QueIns(doc_ne,doc_ce);
      doc->cur_entry=doc_ne;
      doc->cur_col=doc_ne->min_col;
    } else
      if (doc_ce!=doc)
	doc->cur_entry=doc_ce->next;
  }
  while (doc_e!=doc2) {
    if (doc_e->type_u8!=DOCT_SOFT_NEW_LINE) {
      doc_ne=DocEntryCopy(doc,doc_e);
      QueIns(doc_ne,doc->cur_entry->last);
    }
    doc_e=doc_e->next;
  }
  DocRecalc(doc);
  if (unlock_doc2)
    DocUnlock(doc2);
  if (unlock_doc)
    DocUnlock(doc);
}

