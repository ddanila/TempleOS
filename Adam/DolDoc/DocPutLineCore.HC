public CDocEntry *DocPutLine(CDoc *doc=NULL,CDocEntry *doc_e)
{//Send line from other doc to StdOut $LK,"DocPut",A="MN:DocPut"$.
  I64 ch;
  U8 *ptr,*ptr2;
  Bool unlock;
  if (!doc && !(doc=DocPut) || doc->doc_signature!=DOC_SIGNATURE_VAL)
    return NULL;
  unlock=DocLock(doc);
  while (doc_e!=doc && doc_e->type_u8!=DOCT_NEW_LINE) {
    if (doc_e->de_flags&DOCEF_TAG) {
      ptr=doc_e->tag;
      do {
	ptr2=ptr;
	while (ch=*ptr)
	  if (ch=='$$')
	    break;
	  else
	    ptr++;
	*ptr=0;
	"%s",ptr2;
	*ptr=ch;
	if (ch=='$$') {
	  "$$$$";
	  ptr++;
	}
      } while (ch);
    } else if (doc_e->type_u8==DOCT_TAB)
      '\t';
    doc_e=doc_e->next;
  }
  '\n';
  if (doc_e!=doc)
    doc_e=doc_e->next;
  if (unlock)
    DocUnlock(doc);
  return doc_e;
}
