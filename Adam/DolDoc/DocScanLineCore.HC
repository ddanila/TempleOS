//Original canonical document-to-line extraction, shared by both targets.
public U8 *DocScanLine(CDoc *doc,CDocEntry *doc_e,
	I64 *cur_col=NULL,CDocEntry **_do_e_end=NULL)
{//Start at entry in doc,make and return one line as str.
  CDocEntry *doc_e2=doc_e;
  Bool unlock=DocLock(doc);
  U8 *dst,*src,*start,*res;
  I64 i=0;
  if (cur_col)
    *cur_col=-1;
  while (doc_e2!=doc && doc_e2->type_u8!=DOCT_NEW_LINE) {
    if (doc_e2->de_flags&DOCEF_TAG && doc_e2->tag) {
      src=doc_e2->tag;
      i+=StrLen(src);
    } else if (doc_e2->type_u8==DOCT_TAB)
      i++;
    else if (doc_e2->type_u8==DOCT_SHIFTED_X ||
	  doc_e2->type_u8==DOCT_SHIFTED_Y) {
      if (doc_e2->attr<0)
	i++;
      i+=6; //$$SY,3$$
    }
    doc_e2=doc_e2->next;
  }
  res=MAlloc(i+1);
  dst=res;
  while (doc_e!=doc && doc_e->type_u8!=DOCT_NEW_LINE) {
    start=dst;
    if (doc_e->de_flags&DOCEF_TAG && doc_e->tag) {
      src=doc_e->tag;
      while (*src)
	*dst++=*src++;
    } else if (doc_e->type_u8==DOCT_TAB)
      *dst++='\t';
    else if (doc_e->type_u8==DOCT_SHIFTED_Y) {
      *dst(U32 *)++='$$SY,';
      if (doc_e->attr<0)
	*dst++='-';
      *dst++='0'+AbsI64(doc_e->attr); //Supposedly -7 to 7 (single digit)
      *dst++='$$';
    } else if (doc_e->type_u8==DOCT_SHIFTED_X) {
      *dst(U32 *)++='$$SX,';
      if (doc_e->attr<0)
	*dst++='-';
      *dst++='0'+AbsI64(doc_e->attr); //Supposedly -7 to 7 (single digit)
      *dst++='$$';
    }
    if (doc_e==doc->cur_entry && cur_col)
      *cur_col=start-res+doc->cur_col;
    doc_e=doc_e->next;
  }
  if (_do_e_end) *_do_e_end=doc_e;
  *dst=0;
  if (doc_e==doc->cur_entry && cur_col && !doc->cur_col)
    *cur_col=dst-res;
  if (unlock)
    DocUnlock(doc);
  return res;
}
