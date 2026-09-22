//Load the ordinary-text subset produced by DocBasicSaveCore, preserving the
//TempleOS cursor byte in the canonical document cursor fields.
Bool DocBasicLoadCore(CDoc *doc,U8 *source,I64 size)
{
  CDocEntry *cursor_entry=0;
  I64 cursor_col=0,index;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL || !source || size<0) return FALSE;
  DocRst(doc,TRUE);
  for(index=0;index<size;index++) {
    if(source[index]==CH_CURSOR) {
      cursor_entry=doc->head.last;
      if(cursor_entry==doc) cursor_col=0;
      else cursor_col=cursor_entry->max_col;
    } else if(0x20<=source[index]<0x100)
      DocPutKey(doc,source[index],0);
    else return FALSE;
  }
  if(cursor_entry) { doc->cur_entry=cursor_entry; doc->cur_col=cursor_col; }
  return TRUE;
}
