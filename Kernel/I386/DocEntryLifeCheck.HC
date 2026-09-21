I64 DocEntryLifeCheck()
{
  CDoc doc;
  CDocEntry *a,*b,*tail,*rich,*soft;
  CDocBin *bin;
  CDocUndo *undo;
  I64 before=Fs->data_heap->used_u8s,result=8;
  MemSet(&doc,0,sizeof(doc)); doc.mem_task=Fs; doc.win_task=Fs;
  doc.doc_signature=DOC_SIGNATURE_VAL; doc.head.type=DOCT_ERROR;
  doc.head.next=doc.head.last=&doc; doc.cur_entry=&doc;
  QueInit(&doc.bin_head); QueInit(&doc.undo_head);
  a=DocEntryNewBase(&doc,DOCT_TEXT); a->tag=StrNew("abcd"); a->max_col=4;
  DocInsEntry(&doc,a);
  if(doc.head.next!=a || doc.head.last!=a || doc.cur_entry!=&doc) result=-1;
  doc.cur_entry=a; doc.cur_col=2;
  b=DocEntryNewBase(&doc,DOCT_NEW_LINE); DocInsEntry(&doc,b); tail=b->next;
  if(a->next!=b || tail==&doc || StrCmp(a->tag,"ab") || StrCmp(tail->tag,"cd") ||
      a->max_col!=2 || tail->max_col!=2 || doc.cur_entry!=tail || doc.cur_col) result=-2;
  soft=DocEntryNewBase(&doc,DOCT_SOFT_NEW_LINE); QueIns(soft,b);
  doc.cur_entry=soft; DocRemSoftNewLines(&doc,soft);
  if(b->next!=tail || doc.cur_entry!=tail) result=-3;
  rich=CAlloc(sizeof(CDocEntry)); rich->type=DOCT_TEXT;
  rich->de_flags=DOCEF_TAG|DOCEF_AUX_STR|DOCEF_HAS_BIN|DOCEF_REMALLOC_DATA;
  rich->tag=StrNew("asset"); rich->aux_str=StrNew("format"); rich->data=StrNew("data");
  bin=CAlloc(sizeof(CDocBin)); bin->data=StrNew("binary"); bin->use_cnt=1;
  bin->tag=StrNew("asset"); bin->num=12; rich->bin_num=12; rich->bin_data=bin;
  QueIns(bin,&doc.bin_head); QueIns(rich,tail);
  if(DocBinFindNum(&doc,12)!=bin || DocBinFindTag(&doc,"asset")!=bin ||
      DocBinFindNum(&doc,13) || DocBinFindTag(&doc,0)) result=-4;
  DocBinsValidate(&doc);
  if(bin->num!=1 || rich->bin_num!=1 || bin->use_cnt!=1 || doc.cur_bin_num!=2) result=-5;
  doc.cur_entry=rich; DocEntryDel(&doc,rich);
  if(doc.bin_head.next!=&doc.bin_head || doc.cur_entry!=&doc) result=-6;
  undo=CAlloc(sizeof(CDocUndo)); undo->body=StrNew("undo");
  QueIns(undo,&doc.undo_head); DocUndoCntSet(&doc);
  if(doc.undo_cnt!=1) result=-7;
  QueRem(undo); DocUndoDel(&doc,undo); DocUndoCntSet(&doc);
  DocEntryDel(&doc,a); DocEntryDel(&doc,b); DocEntryDel(&doc,tail);
  if(doc.undo_cnt || doc.head.next!=&doc || doc.head.last!=&doc ||
      doc.owning_task || Fs->data_heap->used_u8s!=before) result=-8;
  return result;
}
