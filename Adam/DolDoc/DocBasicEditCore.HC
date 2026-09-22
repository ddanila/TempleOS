//Shared ordinary-text editing core used while the full DocPutKey dependency
//graph is retained on i386. It operates on canonical CDoc/CDocEntry records.
Bool DocBasicEditCore(CDoc *doc,I64 ch=0,I64 sc=0)
{
  CDocEntry *entry,*fresh;
  U8 *old_text,*new_text,*src,*dst;
  I64 column,length;
  Bool unlock;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return FALSE;
  if(sc.u32[0]&0xE00) return FALSE;
  unlock=DocLock(doc);
  entry=doc->cur_entry;
  if(ch==0 && sc.u8[0]==SC_CURSOR_LEFT) {
    if(doc->cur_col>entry->min_col) doc->cur_col--;
    else if(entry->last!=doc) {
      entry=entry->last; doc->cur_entry=entry;
      if(entry->max_col>entry->min_col) doc->cur_col=entry->max_col-1;
      else doc->cur_col=entry->min_col;
    }
  } else if(ch==CH_BACKSPACE) {
    if(doc->cur_col<=entry->min_col && entry->last!=doc) {
      entry=entry->last; doc->cur_entry=entry; doc->cur_col=entry->max_col;
    }
    if(IsEditableText(entry) && doc->cur_col>entry->min_col) {
      column=--doc->cur_col;
      StrCpy(entry->tag+column,entry->tag+column+1);
      entry->max_col--;
    }
  } else if(0x20<=ch<0x100) {
    if(IsEditableText(entry)) {
      length=StrLen(entry->tag); column=doc->cur_col;
      if(column<entry->min_col) column=entry->min_col;
      if(column>length) column=length;
      old_text=entry->tag; new_text=MAlloc(length+2,doc->mem_task);
      src=old_text; dst=new_text;
      while(column-->0) *dst++=*src++;
      *dst++=ch;
      while(*dst++=*src++);
      entry->tag=new_text; entry->max_col=length+1;
      doc->cur_col++;
      Free(old_text);
    } else {
      fresh=DocEntryNewBase(doc,DOCT_TEXT|doc->settings_head.dft_text_attr<<8);
      fresh->tag=MAlloc(2,doc->mem_task); fresh->tag[0]=ch; fresh->tag[1]=0;
      fresh->max_col=1; QueIns(fresh,entry->last);
    }
  } else {
    if(unlock) DocUnlock(doc);
    return FALSE;
  }
  if(unlock) DocUnlock(doc);
  return TRUE;
}
