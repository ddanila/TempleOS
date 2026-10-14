//Original streaming output; shared by the original and 32-bit consoles.
public U0 DocPrintPartial(CDoc *doc=NULL,U8 *fmt,...)
{//Lets you print half a doc cmd, if you like.
  U8 *buf,*st,*src,*dst,*ptr,*ptr2;
  Bool unlock;
  CDocEntry *doc_ce,*doc_ne;
  I64 ch,i,j;
  if (!doc && !(doc=DocPut))
    return;
  buf=StrPrintJoin(NULL,fmt,argc,argv);
  ptr=buf;
  if (doc->user_put_s && (*doc->user_put_s)(doc,doc->user_put_data,buf)) {
    Free(buf);
    return;
  }
  unlock=DocLock(doc);
  if (doc->cur_entry->type_u8==DOCT_DATA)
    while (ch=*ptr++)
      DocPutKey(doc,ch,0);
  else
    while (ch=*ptr) {
      if (!Bt(char_bmp_safe_dollar,ch) ||
	    doc->flags & (DOCF_OVERSTRIKE|DOCF_IN_DOLLAR)) {
	DocPutKey(doc,ch,0);
	ptr++;
      } else {
	ptr2=ptr++;
	while (TRUE) {
	  ch=*ptr++;
	  if (!Bt(char_bmp_safe_dollar,ch))
	    break;
	}
	ptr--;
	*ptr=0;
	doc_ce=doc->cur_entry;
	j=ptr-ptr2;
	if (IsEditableText(doc_ce)) {
	  dst=st=MAlloc(doc_ce->max_col+j+1,doc->mem_task);
	  src=doc_ce->tag;
	  i=doc->cur_col;
	  doc->cur_col+=j;
	  doc_ce->max_col+=j;
	  while (i-->0)
	    *dst++=*src++;
	  while (j-->0)
	    *dst++=*ptr2++;
	  while (*dst++=*src++);
	  Free(doc_ce->tag);
	  doc_ce->tag=st;
	} else {
	  doc_ne=DocEntryNewTag(doc,doc_ce,ptr2);
	  doc_ne->type=DOCT_TEXT|doc->settings_head.dft_text_attr<<8;
	  doc_ne->de_flags=doldoc.dft_de_flags[DOCT_TEXT];
	  QueIns(doc_ne,doc_ce->last);
	  doc->cur_entry=doc_ne;
	  doc->cur_col=StrLen(ptr2);
	}
	*ptr=ch;
	DocRemSoftNewLines(doc,doc->cur_entry);
      }
    }
  if (unlock)
    DocUnlock(doc);
  if (!(doc->flags&DOCF_DONT_SWAP_OUT))
    Yield;
  Free(buf);
}

