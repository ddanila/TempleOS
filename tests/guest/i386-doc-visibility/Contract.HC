I64 DocVisibilityContract()
{
  CDoc *doc=DocNew(NULL,Fs),*saved=Fs->put_doc;I64 mask=0,unrelated=1<<DOCf_PLAIN_TEXT;
  doc->flags=unrelated;
  if(DocCursor(OFF,doc) && Bt(&doc->flags,DOCf_HIDE_CURSOR) &&
     !DocCursor(OFF,doc) && !DocCursor(ON,doc) && !Bt(&doc->flags,DOCf_HIDE_CURSOR) &&
     DocCursor(ON,doc))mask|=1;
  if(DocHighlightCursor(OFF,doc) && Bt(&doc->flags,DOCf_DONT_HIGHLIGHT_CURSOR) &&
     !DocHighlightCursor(OFF,doc) && !DocHighlightCursor(ON,doc) &&
     !Bt(&doc->flags,DOCf_DONT_HIGHLIGHT_CURSOR) && DocHighlightCursor(ON,doc))mask|=2;
  if(DocScroll(OFF,doc) && Bt(&doc->flags,DOCf_NO_SCROLL_BARS) &&
     !DocScroll(OFF,doc) && !DocScroll(ON,doc) && !Bt(&doc->flags,DOCf_NO_SCROLL_BARS) &&
     DocScroll(ON,doc))mask|=4;
  if(doc->flags==unrelated)mask|=8;
  Fs->put_doc=doc;
  if(DocCursor(OFF) && Bt(&doc->flags,DOCf_HIDE_CURSOR) &&
     DocHighlightCursor(OFF) && Bt(&doc->flags,DOCf_DONT_HIGHLIGHT_CURSOR) &&
     DocScroll(OFF) && Bt(&doc->flags,DOCf_NO_SCROLL_BARS))mask|=16;
  Fs->put_doc=NULL;
  if(!DocCursor(ON) && !DocHighlightCursor(ON) && !DocScroll(ON))mask|=32;
  Fs->put_doc=saved;DocDel(doc);return mask;
}
