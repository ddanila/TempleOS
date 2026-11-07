U0 STLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U8 st_text[24];
I64 STCase(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,sc=0;
  CDoc *d=DocNew("SelectedTyping.DD"),*put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *entry;U8 *wanted="AKeep",*text;
  Bool selected=mode>=2;
  if(mode&1)wanted="zKeep";else sc=SCF_SHIFT;
  DocPrint(d,"Keep");DocTop(d);d->flags|=DOCF_DONT_SWAP_OUT;
  entry=d->cur_entry;if(selected)entry->type|=DOCET_SEL;
  StrCpy(keydev.desc,"unset");DocPutKey(d,*wanted,sc);
  text=DocScanLine(d,d->head.next);
  if(text && StrLen(text)<6)StrCpy(st_text+mode*6,text);
  if(text && !StrCmp(text,wanted))m|=1;Free(text);
  if(d->cur_entry==entry && d->cur_col==1)m|=2;
  if(d->head.next==entry && ((entry->type&DOCET_SEL)!=0)==selected)m|=4;
  if(!StrCmp(keydev.desc,"unset"))m|=8;
  if(!Bt(&d->locked_flags,DOClf_LOCKED))m|=16;
  if(DocPut==put && DocDisplay==display && DocBorder==border)m|=32;
  DocDel(d);if(Fs->data_heap->used_u8s==before)m|=64;
  return m;
}
U0 STCheck()
{
  I64 i,masks[4];U8 *s;
  MemSet(st_text,0,sizeof(st_text));
  for(i=0;i<4;i++)masks[i]=STCase(i);
  s=MStrPrint("EXPORT selected-masks.bin %X %X\n",masks,sizeof(masks));STLog(s);Free(s);
  s=MStrPrint("EXPORT selected-text.bin %X %X\n",st_text,sizeof(st_text));STLog(s);Free(s);
  STLog("DOC SELECTED TYPING DONE\n");Sleep(1000);
}
