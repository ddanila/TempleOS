I64 DocReadMissingContract()
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*doc;
  U8 *absolute=FileNameAbs("::/Probe/NoSuchDocument.DD");
  I64 mask=0;
  doc=DocRead("::/Probe/NoSuchDocument.DD",DOCF_PLAIN_TEXT|DOCF_NO_CURSOR);
  if(doc && doc->doc_signature==DOC_SIGNATURE_VAL) {
    mask|=1;
    if((doc->flags&(DOCF_PLAIN_TEXT|DOCF_NO_CURSOR))==
       (DOCF_PLAIN_TEXT|DOCF_NO_CURSOR))mask|=2;
    if(!Bt(&doc->locked_flags,DOClf_LOCKED) && doc->head.next==doc->head.last)mask|=4;
    if(!StrCmp(doc->filename.name,absolute))mask|=16;
    DocDel(doc);
  }
  if(DocPut==put && DocDisplay==display && DocBorder==border)mask|=8;
  Free(absolute);
  return mask;
}
