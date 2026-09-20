I64 DocFormNavCheck()
{
  CDoc doc;
  CDocEntry a,b,c;
  MemSet(&doc,0,sizeof(doc)); MemSet(&a,0,sizeof(a));
  MemSet(&b,0,sizeof(b)); MemSet(&c,0,sizeof(c));
  doc.head.type=DOCT_ERROR; doc.head.next=&a; doc.head.last=&c;
  a.last=&doc; a.next=&b; b.last=&a; b.next=&c; c.last=&b; c.next=&doc;
  a.type=DOCT_INDENT; b.type=DOCT_TEXT; c.type=DOCT_DATA;
  a.min_col=2; b.min_col=4; c.min_col=6;
  doc.cur_entry=&a; DocFormFwd(&doc);
  if(doc.cur_entry!=&b || doc.cur_col!=4) return -1;
  doc.cur_entry=&a; DocFormBwd(&doc);
  if(doc.cur_entry!=&b || doc.cur_col!=4) return -2;
  doc.flags=DOCF_FORM; DocFormFwd(&doc);
  if(doc.cur_entry!=&c || doc.cur_col!=6) return -3;
  doc.cur_entry=&b; DocFormBwd(&doc);
  if(doc.cur_entry!=&c || doc.cur_col!=6) return -4;
  c.de_flags=DOCEF_SKIP_IN_FORM; doc.cur_entry=&a; DocFormFwd(&doc);
  if(doc.cur_entry!=&doc || doc.cur_col) return -5;
  doc.cur_entry=&b; DocFormBwd(&doc);
  if(doc.cur_entry!=&doc || doc.cur_col) return -6;
  a.type=DOCT_TEXT; a.de_flags=DOCEF_LINK;
  doc.cur_entry=&b; DocFormBwd(&doc);
  if(doc.cur_entry!=&a || doc.cur_col!=2) return -7;
  doc.cur_entry=&doc; DocFormFwd(&doc);
  if(doc.cur_entry!=&a || doc.cur_col!=2) return -8;
  return 8;
}
