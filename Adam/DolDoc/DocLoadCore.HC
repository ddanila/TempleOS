public U0 DocLoad(CDoc *doc,U8 *src2,I64 size)
{//Fetch doc from raw mem buf.
  I64 i;
  U8 *src;
  Bool unlock=DocLock(doc);
  CDocBin *tmpb;
  doc->find_replace->filter_lines=0;
  if (src2) {
    DocPutS(doc,src2); //Too big $LK,"DocPrint",A="MN:DocPrint"$() is wasteful.
    src=src2+StrLen(src2)+1;
    i=size-(offset(CDocBin.end)-offset(CDocBin.start));
    while (src<=src2+i) {
      tmpb=CAlloc(sizeof(CDocBin),doc->mem_task);
      MemCpy(&tmpb->start,src,offset(CDocBin.end)-offset(CDocBin.start));
      src+=offset(CDocBin.end)-offset(CDocBin.start);
      tmpb->data=MAlloc(tmpb->size,doc->mem_task);
      if (tmpb->size) {
	MemCpy(tmpb->data,src,tmpb->size);
	src+=tmpb->size;
      }
      QueIns(tmpb,doc->bin_head.last);
      if (tmpb->num>=doc->cur_bin_num)
	doc->cur_bin_num=tmpb->num+1;
    }
  }
  if (!(doc->flags & (DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS)))
    DocBinsValidate(doc);
  DocTop(doc); //Calls $LK,"DocRecalc",A="MN:DocRecalc"$().  DOCT_CURSOR will be set.
  if (unlock)
    DocUnlock(doc);
}

