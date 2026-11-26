public I64 LineRep1(CDirEntry *tmpde)
{
  CDoc *doc;
  I64 res=0,i;
  while (tmpde) {
    i=0;
    if (tmpde->attr&RS_ATTR_DIR)
      i=LineRep1(tmpde->sub);
    else {
      doc=DocRead(tmpde->full_name);
      if (doc->head.next!=doc)
	i=doc->head.last->y+2;
      DocDel(doc);
    }
    tmpde->user_data=i;
    res+=i;
    tmpde=tmpde->next;
  }
  return res;
}
public U0 LineRep2(CDoc *doc,CDirEntry *tmpde)
{
  while (tmpde) {
    if (tmpde->attr&RS_ATTR_DIR) {
      DocPrint(doc,"%8,d $$TR+C,\"%s\"$$\n$$ID,2$$",tmpde->user_data,tmpde->name);
      LineRep2(doc,tmpde->sub);
      DocPrint(doc,"$$ID,-2$$");
    } else
      DocPrint(doc,"%8,d $$LK,\"%s\",A=\"FI:%s\"$$\n",
	    tmpde->user_data,tmpde->name,tmpde->full_name);
    tmpde=tmpde->next;
  }
}
