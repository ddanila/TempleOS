//Load the ordinary-text subset produced by DocBasicSaveCore, preserving the
//TempleOS cursor byte in the canonical document cursor fields.
Bool DocBasicLoadCore(CDoc *doc,U8 *source,I64 size)
{
  CDocEntry *cursor_entry=0;
  Bool found_cursor=FALSE;
  I64 cursor_col=0,index;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL || !source || size<0) return FALSE;
  DocRst(doc,TRUE);
  for(index=0;index<size;index++) {
    if(source[index]==CH_CURSOR) {
      found_cursor=TRUE;
      cursor_entry=doc->head.last;
      if(cursor_entry==doc) cursor_col=0;
      else cursor_col=cursor_entry->max_col;
    } else if(source[index]=='\n' || source[index]=='\t')
      DocPutKey(doc,source[index],0);
    else if(0x20<=source[index]<0x100)
      DocPutKey(doc,source[index],0);
    else return FALSE;
  }
  if(found_cursor) {
    if(cursor_entry!=doc && !IsEditableText(cursor_entry)) {
      cursor_entry=cursor_entry->next;
      cursor_col=cursor_entry->min_col;
    }
    doc->cur_entry=cursor_entry; doc->cur_col=cursor_col;
  }
  else {
    doc->cur_entry=doc->head.next;
    doc->cur_col=doc->cur_entry->min_col;
  }
  return TRUE;
}
