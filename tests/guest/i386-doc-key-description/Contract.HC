U0 KDLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool KDLine(CDoc *d)
{U8 *s=DocScanLine(d,d->head.next);Bool okay=s&&!StrCmp(s,"Keep");Free(s);return okay;}
U8 kd_edits[12];
I64 KDEditControl(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,sc=0;
  CDoc *d=DocNew("DescriptionEditControl.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *entry;U8 *wanted="AKeep",*text;
  Bool selected=FALSE,cursor=FALSE;
  if(mode)wanted="zKeep";else sc=SCF_SHIFT;
  DocPrint(d,"Keep");DocTop(d);d->flags|=DOCF_DONT_SWAP_OUT;
  StrCpy(keydev.desc,"unset");DocPutKey(d,*wanted,sc);
  text=DocScanLine(d,d->head.next);
  if(text && StrLen(text)==5)StrCpy(kd_edits+mode*6,text);
  if(text && !StrCmp(text,wanted))m|=1;Free(text);
  if(d->cur_entry==d)cursor=TRUE;
  for(entry=d->head.next;entry!=d;entry=entry->next) {
    if(entry->type&DOCET_SEL)selected=TRUE;
    if(entry==d->cur_entry && entry->min_col<=d->cur_col<=entry->max_col)cursor=TRUE;
  }
  if(!selected)m|=2;
  if(!StrCmp(keydev.desc,"unset"))m|=4;
  if(cursor)m|=8;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=16;
  if(DocPut==put && DocDisplay==display && DocBorder==border)m|=32;
  DocDel(d);if(Fs->data_heap->used_u8s==before)m|=64;
  return m;
}
U0 KDCheck()
{
  I64 i,ch,sc,col,before,masks[9],controls[2];
  U8 *wanted,*s;
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *entry;
  for(i=0;i<9;i++) {
    ch=0;sc=SCF_KEY_DESC;wanted="";
    switch(i) {
      case 0:ch='A';sc|=SCF_SHIFT;wanted="Char  /'A'";break;
      case 1:ch='z';wanted="Char  /'z'";break;
      case 2:ch='0';wanted="Char  /'0'";break;
      case 3:ch=36;wanted="Char  /'$$'";break;
      case 4:ch=CH_SPACE;wanted="Char  /'SPACE'";break;
      case 5:ch='\t';wanted="Char  /'TAB'";break;
      case 6:ch='\n';wanted="Char  /'ENTER'";break;
      case 7:ch=CH_SHIFT_SPACE;wanted="Char  /'SHIFT_SPACE'";break;
      case 8:ch=CH_CTRLC;sc|=SCF_CTRL;wanted="Edit/Copy to Clip";break;
    }
    before=Fs->data_heap->used_u8s;
    d=DocNew("KeyDescription.DD");DocPrint(d,"Keep");DocTop(d);
    d->flags|=DOCF_DONT_SWAP_OUT;
    entry=d->cur_entry;col=d->cur_col;entry->type|=DOCET_SEL;
    StrCpy(keydev.desc,"unset");
    DocPutKey(d,ch,sc);
    masks[i]=0;
    if(KDLine(d))masks[i]|=1;
    if(d->cur_entry==entry && d->cur_col==col)masks[i]|=2;
    if(d->head.next==entry && entry->type&DOCET_SEL)masks[i]|=4;
    if(!StrCmp(keydev.desc,wanted))masks[i]|=8;
    if(!Bt(&d->locked_flags,DOClf_LOCKED))masks[i]|=16;
    if(DocPut==put && DocDisplay==display && DocBorder==border)masks[i]|=32;
    DocDel(d);
    if(Fs->data_heap->used_u8s==before)masks[i]|=64;
  }
  s=MStrPrint("EXPORT description-masks.bin %X %X\n",masks,sizeof(masks));KDLog(s);Free(s);
  MemSet(kd_edits,0,sizeof(kd_edits));
  controls[0]=KDEditControl(0);controls[1]=KDEditControl(1);
  s=MStrPrint("EXPORT description-controls.bin %X %X\n",controls,sizeof(controls));KDLog(s);Free(s);
  s=MStrPrint("EXPORT description-edits.bin %X %X\n",kd_edits,sizeof(kd_edits));KDLog(s);Free(s);
  KDLog("DOC KEY DESCRIPTION DONE\n");Sleep(1000);
}
