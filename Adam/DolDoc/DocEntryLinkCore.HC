public U8 *DocEntryLink(CDoc *doc,CDocEntry *doc_e)
{//MAlloc new str, either tag or aux_str if link.
  if (doc_e->de_flags&DOCEF_LINK) {
    if (doc_e->de_flags & DOCEF_AUX_STR)
      return StrNew(doc_e->aux_str,doc->mem_task);
    else if (doc_e->de_flags & DOCEF_TAG)
      return StrNew(doc_e->tag,doc->mem_task);
  }
  return NULL;
}
