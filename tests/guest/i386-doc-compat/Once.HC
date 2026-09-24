U0 Report(U8 *text) { while(*text) OutU8(0xE9,*text++); }
U0 NativeDocCompatibilityRead()
{
  CDoc *doc=DocRead("T:/NativeCompat.DD");
  CDocEntry *entry;
  CDocBin *bin;
  U8 *saved,*line;
  I64 size;
  if(!doc) { Report("FAIL original native document read\n"); return; }
  entry=doc->head.next; bin=doc->bin_head.next;
  if(entry==doc || entry->next!=doc || entry->type_u8!=DOCT_SPRITE ||
      StrCmp(entry->tag,"dot") || entry->bin_num!=1 || entry->bin_data!=bin ||
      bin==&doc->bin_head || bin->next!=&doc->bin_head || bin->size!=5 ||
      bin->use_cnt!=1 || bin->data[0]!=1 || bin->data[1]!=2 ||
      bin->data[2]!=0 || bin->data[3]!=0xFF || bin->data[4]!=42) {
    Report("FAIL original native document contents\n"); DocDel(doc); return;
  }
  saved=DocSave(doc,&size); DocDel(doc);
  if(!saved || size!=37) { Report("FAIL original native document save\n"); return; }
  line=MStrPrint("EXPORT NativeRoundTrip.DD %X %X\n",saved,size);
  Report(line); Free(line);
  Report("DONE original native document compatibility\n");
}
NativeDocCompatibilityRead;
