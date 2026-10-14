//Caller holds the document lock. TRUE consumes the key; FALSE inserts it.
U0 ChkDollarBufSize(CDoc *doc)
{
  U8 *buffer;
  I64 size;
  if(doc->dollar_buf_ptr>=doc->dollar_buf_size-2) {
    if(doc->dollar_buf_size>I64_MAX/2) throw('OutMem',TRUE);
    size=doc->dollar_buf_size<<1;
    buffer=MAlloc(size,doc->mem_task);
    MemCpy(buffer,doc->dollar_buf,doc->dollar_buf_ptr);
    Free(doc->dollar_buf);
    doc->dollar_buf=buffer;doc->dollar_buf_size=size;
  }
}

Bool DocDollarInputCore(CDoc *doc,I64 ch,Bool printable)
{
  if(doc->flags&DOCF_IN_DOLLAR) {
    if(!printable) return TRUE;
    ChkDollarBufSize(doc);
    doc->dollar_buf[doc->dollar_buf_ptr++]=ch;
    if(ch=='$$') {
      if(doc->dollar_buf_ptr==2) {
        doc->flags&=~DOCF_IN_DOLLAR;
        doc->dollar_buf_ptr=0;
        return FALSE;
      }
      doc->dollar_buf[doc->dollar_buf_ptr]=0;
      doc->flags&=~DOCF_IN_DOLLAR;
      DocPrint(doc,"%s",doc->dollar_buf);
      doc->dollar_buf_ptr=0;
    }
    return TRUE;
  }
  if(ch=='$$' && !(doc->flags&(DOCF_PLAIN_TEXT|DOCF_PLAIN_TEXT_TABS))) {
    doc->flags|=DOCF_IN_DOLLAR;
    doc->dollar_buf_ptr=0;
    doc->dollar_buf[doc->dollar_buf_ptr++]=ch;
    return TRUE;
  }
  return ch=='\r';
}
