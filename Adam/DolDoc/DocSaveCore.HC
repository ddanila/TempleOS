public U8 *DocSave(CDoc *doc,I64 *_size=NULL)
{//Store doc to raw mem buf.
  CDocEntry *doc_e,*doc_e1;
  CDocBin *b;
  Bool unlock=DocLock(doc);
  I64 ch,cnt=1;//terminator
  U8 *st,*res,*dst,*src;

  if (!(doc->flags & (DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS)))
    DocBinsValidate(doc);
  if (doc->flags&DOCF_NO_CURSOR)
    DocRecalc(doc);
  else {
    DocRecalc(doc,RECALCF_ADD_CURSOR);
    if (doc->head.next->type_u8==DOCT_CURSOR)
      DocEntryDel(doc,doc->head.next); //If no cursor, $LK,"DocLoad",A="MN:DocLoad"$() puts at top.
  }
  for (doc_e=doc->head.next;doc_e!=doc;doc_e=doc_e->next) {
    if (!Bt(doldoc.type_flags_data,doc_e->type_u8)) {
      switch (doc_e->type_u8) {
	case DOCT_TAB:
	case DOCT_PAGE_BREAK:
	case DOCT_CURSOR:
	  cnt++;
	  break;
	case DOCT_NEW_LINE:
	  if (doc->flags&DOCF_CARRIAGE_RETURN)
	    cnt+=2;
	  else
	    cnt++;
	  break;
	case DOCT_SOFT_NEW_LINE:
	  break;
	case DOCT_TEXT:
	  if (!(doc_e->de_flags & ~(DOCEF_TAG|DOCG_BL_IV_UL|DOCEF_WORD_WRAP|
		DOCEF_HIGHLIGHT|DOCEF_SKIP|DOCEF_FILTER_SKIP))&&
		!(doc_e->type&DOCG_BL_IV_UL)) {
	    cnt+=StrLen(doc_e->tag);
	    if (!(doc->flags & (DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS)) ||
		  doc->flags&DOCF_DBL_DOLLARS)
	      cnt+=StrOcc(doc_e->tag,'$$');
	    break;
	  }
	default:
	  st=Doc2PlainText(doc,doc_e);
	  cnt+=StrLen(st)+2;
	  Free(st);
      }
    }
  }
  for (b=doc->bin_head.next;b!=&doc->bin_head;b=b->next)
    if (b->use_cnt>b->tmp_use_cnt)
      cnt+=offset(CDocBin.end)-offset(CDocBin.start)+b->size;
  res=MAlloc(cnt);
  dst=res;
  doc_e=doc->head.next;
  while (doc_e!=doc) {
    doc_e1=doc_e->next;
    if (!Bt(doldoc.type_flags_data,doc_e->type_u8))
      switch (doc_e->type_u8) {
	case DOCT_CURSOR:
	  DocEntryDel(doc,doc_e);
	  *dst++=CH_CURSOR;
	  break;
	case DOCT_TAB:
	  *dst++='\t';
	  break;
	case DOCT_NEW_LINE:
	  if (doc->flags&DOCF_CARRIAGE_RETURN)
	    *dst++='\r';
	  *dst++='\n';
	  break;
	case DOCT_SOFT_NEW_LINE:
	  break;
	case DOCT_TEXT:
	  if (!(doc_e->de_flags & ~(DOCEF_TAG|DOCG_BL_IV_UL|DOCEF_WORD_WRAP|
		DOCEF_HIGHLIGHT|DOCEF_SKIP|DOCEF_FILTER_SKIP)) &&
		!(doc_e->type&DOCG_BL_IV_UL)) {
	    src=doc_e->tag;
	    while (ch=*src++) {
	      *dst++=ch;
	      if (ch=='$$' && (!(doc->flags & (DOCF_PLAIN_TEXT|
		    DOCF_PLAIN_TEXT_TABS)) || doc->flags&DOCF_DBL_DOLLARS))
		*dst++=ch;
	    }
	    break;
	  }
	default:
	  *dst++='$$';
	  st=Doc2PlainText(doc,doc_e);
	  StrCpy(dst,st);
	  dst+=StrLen(st);
	  *dst++='$$';
	  Free(st);
      }
    doc_e=doc_e1;
  }
  *dst++=0;
  b=doc->bin_head.next;
  if (b!=&doc->bin_head) {
    do {
      if (b->use_cnt>b->tmp_use_cnt) {
	MemCpy(dst,&b->start,offset(CDocBin.end)-offset(CDocBin.start));
	dst+=offset(CDocBin.end)-offset(CDocBin.start);
	MemCpy(dst,b->data,b->size);
	dst+=b->size;
      }
      b=b->next;
    } while (b!=&doc->bin_head);
  } else
    cnt--; //No terminator
  if (_size) *_size=cnt;
  if (unlock)
    DocUnlock(doc);
  return res;
}

