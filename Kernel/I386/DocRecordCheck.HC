//Shared original-x64 and native test of wide fields, callbacks and saved bytes.
I64 DocRecordCallback(CDoc *doc,CDocEntry *entry)
{ return doc->user_data+entry->left_exp; }
I64 DocRecordCheck()
{
  CDoc doc;
  CDocEntry entry;
  CDocBin bin;
  U8 *span=&bin.start;
  bin.next=bin.last=&bin;
  bin.num=0x12345678; bin.flags=0x90ABCDEF;
  bin.size=0x10203040; bin.use_cnt=0x50607080;
  if((&bin.end)(U8 *)-span!=16 || span(U64 *)[0]!=0x90ABCDEF12345678 ||
      span(U64 *)[1]!=0x5060708010203040 || bin.next!=&bin || bin.last!=&bin) return -1;
  doc.flags=DOCF_UNDO_DIRTY|DOCF_WORD_WRAP;
  doc.doc_signature=DOC_SIGNATURE_VAL;
  doc.user_data=0x100000028; entry.left_exp=2;
  doc.cur_entry=&entry; doc.head.next=&entry; entry.last=&doc.head;
  if(doc.flags!=(0x1000000000|DOCF_WORD_WRAP) || doc.doc_signature!='DocS' ||
      doc.cur_entry!=&entry || doc.head.next!=&entry || entry.last!=&doc.head) return -2;
  doc.left_click_link=&DocRecordCallback;
  entry.right_cb=&DocRecordCallback;
  if(doc.left_click_link(&doc,&entry)!=0x10000002A ||
      entry.right_cb(&doc,&entry)!=0x10000002A) return -3;
  doc.filename.name[255]=91; doc.settings_head.brace_depth=23;
  doc.bin_head.use_cnt=0xFFFFFFFF; doc.undo_head.time_stamp=0x1234567887654321;
  if(doc.filename.name[255]!=91 || doc.settings_head.brace_depth!=23 ||
      doc.bin_head.use_cnt!=0xFFFFFFFF || doc.undo_head.time_stamp!=0x1234567887654321) return -4;
  return 4;
}
