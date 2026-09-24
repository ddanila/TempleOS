//First record serializer slice.  Dollar is numeric so loading this source as a
//DolDoc document cannot turn the test syntax itself into formatting entries.
U8 *NativeDocRecordSaveCore(CDoc *doc,I64 *_size=NULL)
{
  CDocEntry *entry;
  CDocBin *bin;
  U8 *result,*dst,*src,*tag;
  I64 count=0,index,value,digits;
  Bool unlock,cursor_at_start,save_cursor;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return NULL;
  unlock=DocLock(doc);
  DocBinsValidate(doc);
  cursor_at_start=doc->cur_entry==doc->head.next &&
    doc->cur_col==doc->cur_entry->min_col;
  save_cursor=!(doc->flags&DOCF_NO_CURSOR) && !cursor_at_start;
  entry=doc->head.next;
  while(entry!=doc) {
    if(entry->type_u8==DOCT_TEXT) {
      src=entry->tag; index=0;
      while(src[index]) {
        if(src[index++]==36) count+=2; else count++;
      }
    }
    else if(entry->type_u8==DOCT_TAB || entry->type_u8==DOCT_PAGE_BREAK ||
        entry->type_u8==DOCT_CURSOR || entry->type_u8==DOCT_NEW_LINE) count++;
    else if(entry->type_u8==DOCT_FOREGROUND || entry->type_u8==DOCT_BACKGROUND ||
        entry->type_u8==DOCT_BLINK || entry->type_u8==DOCT_INVERT ||
        entry->type_u8==DOCT_UNDERLINE) {
      if(entry->attr==DOC_DFT) count+=4;
      else if(0<=entry->attr<=9 &&
          (entry->type_u8==DOCT_FOREGROUND || entry->type_u8==DOCT_BACKGROUND ||
           entry->attr<=1)) count+=6;
      else if((entry->type_u8==DOCT_FOREGROUND || entry->type_u8==DOCT_BACKGROUND) &&
          entry->attr<=15) count+=7;
      else { if(unlock) DocUnlock(doc); return NULL; }
    } else if(entry->type_u8==DOCT_SPRITE && entry->bin_data && entry->bin_num>0) {
      tag=entry->tag; if(!tag) tag="";
      value=entry->bin_num; digits=1;
      while(value>=10) { value/=10; digits++; }
      count+=11+StrLen(tag)+digits;
    } else if(entry->type_u8!=DOCT_SOFT_NEW_LINE) {
      if(unlock) DocUnlock(doc); return NULL;
    }
    entry=entry->next;
  }
  if(save_cursor) count++;
  bin=doc->bin_head.next;
  if(bin!=&doc->bin_head) {
    count++;
    while(bin!=&doc->bin_head) {
      count+=16+bin->size;
      bin=bin->next;
    }
  }
  try { result=MAlloc(count+1,doc->mem_task); }
  catch { if(unlock) DocUnlock(doc); }
  dst=result; entry=doc->head.next;
  while(entry!=doc) {
    if(save_cursor && entry==doc->cur_entry && !IsEditableText(entry)) *dst++=CH_CURSOR;
    if(entry->type_u8==DOCT_TEXT) {
      src=entry->tag; index=0;
      while(src[index]) {
        if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) *dst++=CH_CURSOR;
        if(src[index]==36) *dst++=36;
        *dst++=src[index++];
      }
      if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) *dst++=CH_CURSOR;
    } else if(entry->type_u8==DOCT_TAB) *dst++='\t';
    else if(entry->type_u8==DOCT_PAGE_BREAK || entry->type_u8==DOCT_CURSOR) *dst++=CH_CURSOR;
    else if(entry->type_u8==DOCT_NEW_LINE) *dst++='\n';
    else if(entry->type_u8==DOCT_SPRITE) {
      *dst++=36; *dst++='S'; *dst++='P'; *dst++=','; *dst++='"';
      tag=entry->tag; if(tag) while(*tag) *dst++=*tag++;
      *dst++='"'; *dst++=','; *dst++='B'; *dst++='I'; *dst++='=';
      value=entry->bin_num; digits=1;
      while(value>=10) { value/=10; digits*=10; }
      value=entry->bin_num;
      while(digits) { *dst++='0'+value/digits; value%=digits; digits/=10; }
      *dst++=36;
    }
    else if(entry->type_u8==DOCT_FOREGROUND || entry->type_u8==DOCT_BACKGROUND ||
        entry->type_u8==DOCT_BLINK || entry->type_u8==DOCT_INVERT ||
        entry->type_u8==DOCT_UNDERLINE) {
      *dst++=36;
      if(entry->type_u8==DOCT_FOREGROUND) { *dst++='F'; *dst++='G'; }
      else if(entry->type_u8==DOCT_BACKGROUND) { *dst++='B'; *dst++='G'; }
      else if(entry->type_u8==DOCT_BLINK) { *dst++='B'; *dst++='K'; }
      else if(entry->type_u8==DOCT_INVERT) { *dst++='I'; *dst++='V'; }
      else { *dst++='U'; *dst++='L'; }
      if(entry->attr!=DOC_DFT) {
        *dst++=',';
        if(entry->attr>=10) *dst++='1';
        *dst++='0'+entry->attr%10;
      }
      *dst++=36;
    }
    entry=entry->next;
  }
  if(doc->cur_entry==doc && save_cursor) *dst++=CH_CURSOR;
  bin=doc->bin_head.next;
  if(bin!=&doc->bin_head) {
    *dst++=0;
    while(bin!=&doc->bin_head) {
      MemCpy(dst,&bin->start,16); dst+=16;
      MemCpy(dst,bin->data,bin->size); dst+=bin->size;
      bin=bin->next;
    }
  } else *dst=0;
  if(_size) *_size=count;
  if(unlock) DocUnlock(doc);
  return result;
}
