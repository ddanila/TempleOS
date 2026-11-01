I64 PKContract(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,tabs=0,sc=0;
  CDoc *old_put=DocPut,*old_display=DocDisplay,*d=DocNew("FormTab.DD");
  CDocEntry *e,*first=NULL,*second=NULL,*third=NULL,*want=NULL;
  DocPrint(d,"A\nB\nC");
  for(e=d->head.next;e!=d;e=e->next) if(e->type_u8==DOCT_TEXT) {
    if(!first)first=e;else if(!second)second=e;else if(!third)third=e;
  }
  if(!first || !second || !third) {DocDel(d);return 0;}
  first->de_flags|=DOCEF_LINK;second->de_flags|=DOCEF_LINK;third->de_flags|=DOCEF_LINK;
  d->flags|=DOCF_FORM;d->cur_entry=first;d->cur_col=first->min_col;
  switch(mode) {
    case 0:want=second;break;
    case 1:second->de_flags|=DOCEF_SKIP_IN_FORM;want=third;break;
    case 2:d->cur_entry=third;d->cur_col=third->min_col;want=third;break;
    case 3:d->flags&=~DOCF_FORM;break;
    case 4:first->de_flags&=~DOCEF_LINK;break;
    case 5:d->flags&=~DOCF_FORM;d->flags|=DOCF_OVERSTRIKE;want=first;break;
    case 6:first->de_flags&=~DOCEF_LINK;d->flags|=DOCF_OVERSTRIKE;want=second;break;
    case 7:sc=SCF_SHIFT;want=second;break;
  }
  DocPutKey(d,'\t',sc);
  for(e=d->head.next;e!=d;e=e->next) if(e->type_u8==DOCT_TAB)tabs++;
  if(!want || d->cur_entry==want && d->cur_col==want->min_col)m|=1;
  if((mode==3 || mode==4) && tabs==1 || mode!=3 && mode!=4 && !tabs)m|=2;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=4;
  if(DocPut==old_put && DocDisplay==old_display)m|=8;
  DocDel(d);
  if(Fs->data_heap->used_u8s==before)m|=16;
  return m;
}
I64 PKCheck(I64 mode){I64 m=PKContract(mode);if(m!=31)throw('FormTab',TRUE);return m;}
