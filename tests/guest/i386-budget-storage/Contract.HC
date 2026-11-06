I64 bs_mask,bs_data_size,bs_strings_size;
U8 *bs_data,*bs_strings;
U0 BSPaths()
{
  Cd("~/Budget");
  bgt_string_file=FileNameAbs("Strs.DD.Z");
  bgt_accts_file=FileNameAbs("Accts.DD.Z");
  bgt_data_file=FileNameAbs("Bgt.DATA.Z");
}
U0 BSRead()
{
  CBgtEntry *e;
  BgtAcctsRead;BgtDataRead;
  e=b_head.next;bs_mask=0;
  if(e!=&b_head && e->next==&b_head && e->date==(730000<<32)+0x10000000 &&
      e->amount==125 && !e->type && !e->flags &&
      !StrCmp(e->credit,"BANK") && !StrCmp(e->debit,"RENT") &&
      !StrCmp(e->desc,"rent payment"))bs_mask|=1;
  if(t_head.next==&t_head)bs_mask|=2;
  if(BgtAcctColor("BANK")==BLUE && BgtAcctColor("RENT")==BLACK)bs_mask|=4;
  if(accts_table_strs==11)bs_mask|=8;
  bs_data=FileRead(bgt_data_file,&bs_data_size);
  bs_strings=FileRead(bgt_string_file,&bs_strings_size);
  BgtDel;
}
U0 BSWrite()
{
  CBgtEntry *e;
  BgtAcctsRead;QueInit(&b_head);QueInit(&t_head);
  e=CAlloc(sizeof(CBgtEntry));e->date=(730000<<32)+0x10000000;e->amount=125;
  e->credit=StrNew("BANK");e->debit=StrNew("RENT");e->desc=StrNew("rent payment");
  BgtIns(e);BgtDataWrite;BgtDel;
  BSRead;
}
