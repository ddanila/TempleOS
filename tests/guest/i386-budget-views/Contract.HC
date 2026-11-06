U8 *bv_bank,*bv_rent,*bv_deleted;
I64 bv_bank_size,bv_rent_size,bv_deleted_size,bv_mask;
U0 BVAdd(I64 day,F64 amount,U8 *credit,U8 *debit,U8 *desc)
{
  CBgtEntry *e=CAlloc(sizeof(CBgtEntry));
  e->date=day<<32;e->amount=amount;
  e->credit=StrNew(credit);e->debit=StrNew(debit);e->desc=StrNew(desc);BgtIns(e);
}
U0 BudgetViews()
{
  CDoc *old_put=Fs->put_doc,*old_display=Fs->display_doc,*doc;
  CBgtEntry *middle;
  bv_mask=0;
  Cd("~/Budget");bgt_accts_file=FileNameAbs("Accts.DD.Z");BgtAcctsRead;
  QueInit(&b_head);QueInit(&t_head);
  BVAdd(730002,30,"BANK","RENT","rent");
  BVAdd(730000,100,"WAGES","BANK","salary");
  BVAdd(730001,20,"BANK","FOOD","groceries");
  middle=b_head.next->next;
  if(b_head.next->date==730000<<32 && middle->date==730001<<32 &&
      b_head.last->date==730002<<32)bv_mask|=1;
  Fs->put_doc=Fs->display_doc=NULL;
  StrCpy(view_acct,"BANK");BgtRegen;
  doc=Fs->put_doc;
  if(doc->flags&DOCF_FORM && doc->user_put_key==&BgtPutKey)bv_mask|=2;
  bv_bank=DocSave(doc,&bv_bank_size);
  doc->cur_entry=middle->doc_e;doc->cur_col=0;
  StrCpy(view_acct,"RENT");BgtRegen;
  doc=Fs->put_doc;
  if(doc->cur_entry==middle->doc_e && !doc->cur_col)bv_mask|=4;
  bv_rent=DocSave(doc,&bv_rent_size);
  StrCpy(view_acct,"BANK");
  if(BgtPutKey(doc,NULL,CH_CTRLY,0) && b_head.next->next==b_head.last &&
      b_head.last->next==&b_head && b_head.next->amount==100 && b_head.last->amount==30)bv_mask|=8;
  doc=Fs->put_doc;
  bv_deleted=DocSave(doc,&bv_deleted_size);
  if(!BgtPutKey(doc,NULL,'z',0) && Fs->put_doc==doc)bv_mask|=16;
  Fs->put_doc=old_put;Fs->display_doc=old_display;DocDel(doc);BgtDel;
}
