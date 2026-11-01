#ifndef DOC_CHAR_FORM_ADVANCE_CORE_INCLUDED
#define DOC_CHAR_FORM_ADVANCE_CORE_INCLUDED
//Original EdCharIns form-Tab transition. Caller holds the document lock.
U0 DocCharFormAdvanceCore(CDoc *doc)
{
  doc->cur_entry=doc->cur_entry->next;
  doc->cur_col=doc->cur_entry->min_col;
  DocFormFwd(doc);
}
#endif
