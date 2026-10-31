#ifndef DOC_CHAR_ACTION_CORE_INCLUDED
#define DOC_CHAR_ACTION_CORE_INCLUDED
//Shared original action dispatch from EdCharIns. Caller holds the document lock.
Bool DocCharActionCore(CDoc *doc,I64 ch,I64 sc)
{
  CDocEntry *doc_ce=doc->cur_entry;
  if ((ch==CH_SPACE || ch=='\n') &&
        !(sc & (SCF_CTRL|SCF_SHIFT)) &&
        doc_ce->de_flags &
        (DOCEF_LINK|DOCEF_TREE|DOCEF_LST|DOCEF_CHECK_COLLAPSABLE|
        DOCEF_LEFT_MACRO|DOCEF_LEFT_EXP|DOCEF_LEFT_CB|DOCEF_LEFT_IN_STR |
        DOCEF_RIGHT_MACRO|DOCEF_RIGHT_EXP|DOCEF_RIGHT_CB|DOCEF_RIGHT_IN_STR)) {
    doc->cmd_U8=ch;
    DocEntryRun(doc,doc_ce,FALSE);
    DocLock(doc);
    return TRUE;
  }
  return FALSE;
}
#endif
