//Shared lifecycle contract for the original implementation and retained i386 binding.
I64 doc_lifecycle_delta;
I64 DocLifecycleCheck()
{
  CDoc *doc;
  CDocEntry *entry;
  I64 before,allocated;
  //The original first DocNew lazily initializes recalc/editor state.  Warm that
  //path before measuring ownership so this checks repeatable lifecycle balance.
  doc=DocNew("C:/NativeEdit.Warm.DD",Fs); DocDel(doc);
  before=Fs->data_heap->used_u8s;
  doc=DocNew("C:/NativeEdit.DD",Fs);
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL || doc->mem_task!=Fs ||
      doc->win_task!=Fs || StrCmp(doc->filename.name,"C:/NativeEdit.DD")) return -1;
  if(doc->head.next!=doc || doc->head.last!=doc || doc->cur_entry!=doc ||
      doc->bin_head.next!=&doc->bin_head || doc->undo_head.next!=&doc->undo_head) return -2;
  if(!doc->find_replace || !doc->find_replace->scan_fwd ||
      !doc->find_replace->match_case || !doc->find_replace->pmt ||
      !doc->dollar_buf || doc->dollar_buf_size!=84) return -3;
  entry=DocEntryNewTag(doc,&doc->head,"Hello");
  entry->type=DOCT_TEXT;
  DocInsEntry(doc,entry);
  if(doc->head.next!=entry || doc->head.last!=entry || entry->next!=doc ||
      entry->last!=doc || StrCmp(entry->tag,"Hello")) return -4;
  allocated=DocSize(doc);
  if(allocated<=sizeof(CDoc)+sizeof(CEdFindText)+84) return -5;
  DocRst(doc,TRUE);
  if(doc->head.next!=doc || doc->head.last!=doc || doc->cur_entry!=doc ||
      doc->doc_signature!=DOC_SIGNATURE_VAL) return -6;
  entry=DocEntryNewTag(doc,&doc->head,"Again");
  entry->type=DOCT_TEXT;
  DocInsEntry(doc,entry);
  DocDel(doc);
  doc_lifecycle_delta=Fs->data_heap->used_u8s-before;
  //Original DocRecalc leaves one small 48-byte cache allocation per session.
  //Reject growth beyond that established behavior while native stays at zero.
  if(doc_lifecycle_delta<0 || doc_lifecycle_delta>48) return -7;
  return 7;
}
