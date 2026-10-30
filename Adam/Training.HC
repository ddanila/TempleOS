#help_index "Help System"

#include "/Adam/KeyMapCore.HC"

#help_index "Help System/Training"
public U0 TipOfDay(U8 *tip_file="::/Doc/Tips.DD")
{//Print random tip-of-day from ::/Doc/Tips.DD.
  I64 i=RandU16;
  CDoc *doc=DocRead(tip_file),*doc2=DocNew;
  CDocEntry *doc_e=doc->head.next;
  "$$WW,1$$\n";
  while (TRUE) {
    if (doc_e->type_u8==DOCT_TEXT && *doc_e->tag=='*')
      if (!i--) break;
    doc_e=doc_e->next;
  }
  if (doc_e->type_u8==DOCT_TEXT && *doc_e->tag=='*') {
    while (doc_e!=doc) {
      if (doc_e->type_u8!=DOCT_ERROR)
	DocInsEntry(doc2,DocEntryCopy(doc2,doc_e));
      doc_e=doc_e->next;
      if (doc_e->type_u8==DOCT_TEXT && *doc_e->tag=='*')
	break;
    }
  }
  DocInsDoc(DocPut,doc2);
  DocDel(doc2);
  DocDel(doc);
}
