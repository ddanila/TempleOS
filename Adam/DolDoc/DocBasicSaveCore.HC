//Shared serializer for the ordinary-text subset. Its size result follows
//DocSave: without binary tails the terminating zero is not counted.
U8 *DocBasicSaveCore(CDoc *doc,I64 *_size=NULL)
{
  CDocEntry *entry;
  I64 count=0,index;
  U8 *result,*dst,*src;
  Bool unlock,cursor_at_start,save_cursor;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return NULL;
  unlock=DocLock(doc);
  cursor_at_start=doc->cur_entry==doc->head.next &&
    doc->cur_col==doc->cur_entry->min_col;
  save_cursor=!(doc->flags&DOCF_NO_CURSOR) && !cursor_at_start;
  for(entry=doc->head.next;entry!=doc;entry=entry->next)
    switch(entry->type_u8) {
      case DOCT_TEXT: count+=StrLen(entry->tag); break;
      case DOCT_TAB:
      case DOCT_PAGE_BREAK:
      case DOCT_CURSOR:
      case DOCT_NEW_LINE: count++; break;
      case DOCT_SOFT_NEW_LINE: break;
      default:
        if(unlock) DocUnlock(doc);
        return NULL;
    }
  if(save_cursor) count++;
  try { result=MAlloc(count+1,doc->mem_task); }
  catch { if(unlock) DocUnlock(doc); }
  dst=result;
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    if(save_cursor && entry==doc->cur_entry && !IsEditableText(entry)) {
      dst[0]=CH_CURSOR; dst++;
    }
    switch(entry->type_u8) {
      case DOCT_TEXT:
        src=entry->tag;
        index=0;
        while(src[index]) {
          if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) {
            dst[0]=CH_CURSOR; dst++;
          }
          dst[0]=src[index++]; dst++;
        }
        if(save_cursor && entry==doc->cur_entry && index==doc->cur_col) {
          dst[0]=CH_CURSOR; dst++;
        }
        break;
      case DOCT_TAB: dst[0]='\t'; dst++; break;
      case DOCT_PAGE_BREAK:
      case DOCT_CURSOR: dst[0]=CH_CURSOR; dst++; break;
      case DOCT_NEW_LINE: dst[0]='\n'; dst++; break;
    }
  }
  if(doc->cur_entry==doc && save_cursor) {
    dst[0]=CH_CURSOR; dst++;
  }
  *dst=0;
  if(_size) *_size=count;
  if(unlock) DocUnlock(doc);
  return result;
}
