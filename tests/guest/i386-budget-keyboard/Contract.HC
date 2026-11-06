U8 *bk_before,*bk_after;
I64 bk_before_size,bk_after_size,bk_mask,bk_keys;
U0 BKLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool BKKey(CDoc *doc,U8 *st,I64 ch,I64 sc)
{
  Bool result=BgtPutKey(doc,st,ch,sc);
  if(ch==CH_CTRLY) {
    bk_keys++;
    if(result)bk_mask|=1;
    if(sc&SCF_CTRL)bk_mask|=2;
    BKLog("BK deleted\n");
  }
  return result;
}
U0 BKAdd(I64 day,F64 amount,U8 *credit,U8 *debit,U8 *desc)
{
  CBgtEntry *e=CAlloc(sizeof(CBgtEntry));
  e->date=day<<32;e->amount=amount;
  e->credit=StrNew(credit);e->debit=StrNew(debit);e->desc=StrNew(desc);BgtIns(e);
}
U0 BudgetKeyboard()
{
  CDoc *old_put=Fs->put_doc,*old_display=Fs->display_doc,*doc;
  bk_mask=bk_keys=0;
  Cd("~/Budget");bgt_accts_file=FileNameAbs("Accts.DD.Z");BgtAcctsRead;
  QueInit(&b_head);QueInit(&t_head);
  BKAdd(730002,30,"BANK","RENT","rent");
  BKAdd(730000,100,"WAGES","BANK","salary");
  BKAdd(730001,20,"BANK","FOOD","groceries");
  Fs->put_doc=Fs->display_doc=NULL;
  StrCpy(view_acct,"BANK");BgtRegen;doc=Fs->put_doc;
  doc->cur_entry=b_head.next->next->doc_e;doc->cur_col=0;
  doc->user_put_key=&BKKey;
  bk_before=DocSave(doc,&bk_before_size);
  WinFocus(Fs);
  BKLog("BK ready\n");
  if(View)bk_mask|=4;
  doc=Fs->put_doc;
  if(bk_keys==1 && b_head.next->next==b_head.last && b_head.last->next==&b_head &&
      b_head.next->amount==100 && b_head.last->amount==30)bk_mask|=8;
  if(doc->cur_entry==b_head.last->doc_e)bk_mask|=16;
  bk_after=DocSave(doc,&bk_after_size);
  Fs->put_doc=old_put;Fs->display_doc=old_display;DocDel(doc);BgtDel;
  BKLog(MStrPrint("EXPORT before.DD %X %X\n",bk_before,bk_before_size));
  BKLog(MStrPrint("EXPORT after.DD %X %X\n",bk_after,bk_after_size));
  BKLog(MStrPrint("EXPORT mask.bin %X %X\n",&bk_mask,8));
  BKLog("BK done\n");
}
