I64 DocLoadTextSize(U8 *source,I64 size)
{//Return the bounded text length after checking every binary record.
  I64 index=0,text_size,header=offset(CDocBin.end)-offset(CDocBin.start),payload;
  if (!source || size<0) return -1;
  while (index<size && source[index]) index++;
  text_size=index;
  if (index<size) index++;
  while (index<size) {
    if (size-index<header) return -1;
    payload=*(source+index+offset(CDocBin.size)-offset(CDocBin.start))(U32 *);
    index+=header;
    if (payload>size-index) return -1;
    index+=payload;
  }
  return text_size;
}

U0 DocLoadTerminated(CDoc *doc,U8 *src2,I64 size)
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


public U0 DocLoad(CDoc *doc,U8 *source,I64 size)
{//A size-delimited text buffer need not include a terminator.
  I64 text_size;
  U8 *copy;
  if (!source) {
    DocLoadTerminated(doc,NULL,0);
    return;
  }
  text_size=DocLoadTextSize(source,size);
  if (text_size<0) return;
  if (!size) source=NULL;
  if (text_size<size || !size) {
    DocLoadTerminated(doc,source,size);
    return;
  }
  copy=MAlloc(size+1);
  try {
    MemCpy(copy,source,size);
    copy[size]=0;
    DocLoadTerminated(doc,copy,size);
  } catch {
    Free(copy);
    copy=NULL;
  }
  Free(copy);
}
