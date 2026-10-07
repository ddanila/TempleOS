public Bool DocGoToLine(CDoc *doc,I64 line_num) //one based
{//Nearest to specified line num.  Move cur_entry & center.
  Bool res=FALSE,unlock;
  if (doc) {
    unlock=DocLock(doc);
    doc->x=0;
    doc->y=line_num-1;
    DocRecalc(doc,RECALCt_FIND_CURSOR);
    DocCenter(doc);
    if (doc->cur_entry->y==line_num-1)
      res=TRUE;
    if (unlock)
      DocUnlock(doc);
  }
  return res;
}

public Bool DocFind(CDoc *haystack_doc,I64 start_line_num=I64_MIN,
U8 *needle,I64 match=1)
{//Find str by searching tags. Move cur_entry & center.
  Bool res=FALSE,unlock;
  CDocEntry *doc_e;
  U8 *ptr;
  I64 i;
  if (haystack_doc) {
    unlock=DocLock(haystack_doc);
    if (start_line_num==I64_MIN) {
      res=TRUE;
      doc_e=haystack_doc->head.next;
    } else {
      res=DocGoToLine(haystack_doc,start_line_num);
      doc_e=haystack_doc->cur_entry;
    }
    if (res) {
      if (needle) {
	res=FALSE;
	while (doc_e!=haystack_doc) {
	  if (doc_e->de_flags&DOCEF_TAG && doc_e->tag &&
//TODO: handle multi-DocEntry strs
		(ptr=StrIMatch(needle,doc_e->tag))) {
	    i=ptr-doc_e->tag;
	    if (!--match) {
	      haystack_doc->cur_entry=doc_e;
	      if (i<doc_e->min_col) i=doc_e->min_col;
	      if (i>doc_e->max_col) i=doc_e->max_col;
	      haystack_doc->cur_col=i;
	      res=TRUE;
	      break;
	    }
	  }
	  doc_e=doc_e->next;
	}
      } else
	res=FALSE;
    }
    if (!res) DocBottom(haystack_doc);
    DocCenter(haystack_doc);
    if (unlock)
      DocUnlock(haystack_doc);
  }
  return res;
}

public Bool DocAnchorFind(CDoc *haystack_doc,U8 *needle_str)
{//Find named anchor. Move cur_entry & center.
  Bool res=FALSE,unlock;
  CDocEntry *doc_e;
  if (haystack_doc) {
    unlock=DocLock(haystack_doc);
    doc_e=haystack_doc->head.next;
    if (needle_str)
      while (doc_e!=haystack_doc) {
	if (doc_e->type_u8==DOCT_ANCHOR && doc_e->de_flags & DOCEF_AUX_STR) {
	  if (!StrCmp(needle_str,doc_e->aux_str)) {
	    haystack_doc->cur_entry=doc_e;
	    haystack_doc->cur_col=doc_e->min_col;
	    res=TRUE;
	    break;
	  }
	}
	doc_e=doc_e->next;
      }
    if (!res) DocBottom(haystack_doc);
    DocCenter(haystack_doc);
    if (unlock)
      DocUnlock(haystack_doc);
  }
  return res;
}

