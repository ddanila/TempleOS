I64 DocBinaryPersistenceCheck()
{
  CDoc *doc,*loaded;
  CDocBin *bin;
  CDocEntry *entry;
  U8 *saved;
  I64 before=Fs->data_heap->used_u8s,size,result=8;
  doc=DocNew("C:/BinaryRecord.DD",Fs); doc->flags|=DOCF_NO_CURSOR;
  bin=CAlloc(sizeof(CDocBin));
  bin->num=7; bin->flags=0x1234; bin->size=5; bin->use_cnt=1;
  bin->data=MAlloc(5);
  bin->data[0]=1; bin->data[1]=2; bin->data[2]=0; bin->data[3]=0xFF; bin->data[4]=42;
  QueIns(bin,doc->bin_head.last);
  entry=CAlloc(sizeof(CDocEntry));
  entry->type=DOCT_SPRITE; entry->de_flags=DOCEF_TAG|DOCEF_HAS_BIN;
  entry->tag=StrNew("dot"); entry->bin_num=7; entry->bin_data=bin;
  DocInsEntry(doc,entry);
  if(!DocWrite(doc)) result=-1;
  DocDel(doc); loaded=DocRead("C:/BinaryRecord.DD");
  if(result==8 && !loaded) result=-2;
  if(loaded) {
    entry=loaded->head.next; bin=loaded->bin_head.next;
    if(result==8 && (entry==loaded || entry->next!=loaded ||
        entry->type_u8!=DOCT_SPRITE || StrCmp(entry->tag,"dot") ||
        entry->bin_num!=1 || entry->bin_data!=bin || bin==&loaded->bin_head ||
        bin->next!=&loaded->bin_head || bin->size!=5 || bin->use_cnt!=1 ||
        bin->data[0]!=1 || bin->data[4]!=42)) result=-3;
    saved=DocSave(loaded,&size);
    if(result==8 && (!saved || size!=37 || saved[15] || saved[16]!=1 ||
        saved[20]!=0x34 || saved[21]!=0x12 || saved[24]!=5 ||
        saved[28]!=1 || saved[32]!=1 || saved[36]!=42)) result=-4;
    Free(saved); DocDel(loaded);
  }
  if(Fs->data_heap->used_u8s!=before) result=-5;
  return result;
}
