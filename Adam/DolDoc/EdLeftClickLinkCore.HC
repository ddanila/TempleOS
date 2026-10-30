I64 EdLeftClickLink(CDoc *doc,CDocEntry *doc_e)
{//Called with doc locked, exit unlocked
  Bool res;
  U8 *st;
  if (st=DocEntryLink(doc,doc_e)) {
    DocUnlock(doc);
    if (doc_e->de_flags & DOCEF_POPUP)
      res=PopUpEd(st);
    else
      res=Ed(st);
    Free(st);
    return res;
  }
}
