I64 PKContract(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,sc=0;
  CDoc *old_put=DocPut,*old_display=DocDisplay,*d=DocNew("FormHorizontal.DD");
  CDocEntry *e,*first=NULL,*second=NULL,*third=NULL,*want=NULL;
  Bool first_sel=FALSE;
  DocPrint(d,"A\nB\nC");
  for(e=d->head.next;e!=d;e=e->next) if(e->type_u8==DOCT_TEXT) {
    if(!first)first=e;else if(!second)second=e;else if(!third)third=e;
  }
  if(!first || !second || !third) {DocDel(d);return 0;}
  first->de_flags|=DOCEF_LINK;second->de_flags|=DOCEF_LINK;third->de_flags|=DOCEF_LINK;
  d->flags|=DOCF_FORM;d->cur_entry=first;d->cur_col=first->min_col;
  switch(mode) {
    case 0:sc=SC_CURSOR_RIGHT;want=second;break;
    case 1:sc=SC_CURSOR_LEFT;d->cur_entry=second;d->cur_col=second->min_col;want=first;break;
    case 2:sc=SC_CURSOR_RIGHT;second->de_flags|=DOCEF_SKIP_IN_FORM;want=third;break;
    case 3:sc=SC_CURSOR_LEFT;second->de_flags|=DOCEF_SKIP_IN_FORM;d->cur_entry=third;d->cur_col=third->min_col;want=first;break;
    case 4:sc=SC_CURSOR_RIGHT|SCF_SHIFT;want=second;first_sel=TRUE;break;
    case 5:sc=SC_CURSOR_RIGHT;first->type|=DOCET_SEL;want=second;break;
    case 6:sc=SC_CURSOR_RIGHT|SCF_CTRL;want=first;break;
    case 7:sc=SC_CURSOR_LEFT|SCF_CTRL;d->cur_entry=second;d->cur_col=second->min_col;want=first;break;
  }
  DocPutKey(d,0,sc);
  if(d->cur_entry==want && d->cur_col==want->min_col)m|=1;
  if(!!Bt(&first->type,DOCEt_SEL)==first_sel)m|=2;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=4;
  if(DocPut==old_put && DocDisplay==old_display)m|=8;
  DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=16;
  return m;
}
I64 PKCheck(I64 mode){I64 m=PKContract(mode);if(m!=31)throw('FormMove',TRUE);return m;}
