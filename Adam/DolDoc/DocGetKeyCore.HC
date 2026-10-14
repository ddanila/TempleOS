//Original document input and filter-exit behavior.
#include "/Kernel/KeyDescFlag.HH"
U0 EdUndoFilter(CDoc *doc)
{
  Bool unlock=DocLock(doc);
  CDocEntry *doc_ce=doc->head.next;
  while (doc_ce!=doc) {
    doc_ce->de_flags&=~DOCEF_FILTER_SKIP;
    doc_ce=doc_ce->next;
  }
  doc->find_replace->filter_lines=0;
  if (unlock)
    DocUnlock(doc);
}

public I64 DocGetKey(I64 *_sc=NULL)
{//Called by $LK,"View",A="MN:View"$. You probably don't need this.
  I64 ch,sc;
  Bool cont,old_key_desc;
  do {
    old_key_desc=LBtr(&Fs->win_inhibit,WIf_SELF_KEY_DESC);
    do ch=GetKey(&sc,TRUE);
    while (sc&SCF_KEY_DESC);
    LBEqu(&Fs->win_inhibit,WIf_SELF_KEY_DESC,old_key_desc);

    DocRecalc(DocPut);
    cont=FALSE;
    if ((ch==CH_ESC || ch==CH_SHIFT_ESC) && //Check for exit filter mode
	  DocPut && DocPut->find_replace->filter_lines) {
      EdUndoFilter(DocPut);
      cont=TRUE;
    }
  } while (cont);
  if (_sc) *_sc=sc;
  return ch;
}

