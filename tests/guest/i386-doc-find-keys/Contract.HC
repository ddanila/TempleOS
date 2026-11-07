U0 FNLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 fn_positions[30];
CDoc *FNDoc(U8 *text)
{
  CDoc *d=DocNew("FindKeys.DD");d->flags|=DOCF_PLAIN_TEXT;
  DocLoad(d,text,StrLen(text));d->flags&=~DOCF_PLAIN_TEXT;
  d->flags|=DOCF_DONT_SWAP_OUT;DocTop(d);return d;
}
I64 FNAction(I64 mode)
{
  I64 before=Fs->data_heap->used_u8s,m=0,col=5,sc=SC_F3;
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*d=FNDoc("cat scatter CAT cat_ cat\ncat");
  CDocEntry *first=d->head.next,*last=d->head.last,*want=first;CEdFindText saved;
  StrCpy(d->find_replace->find_text,"cat");d->find_replace->match_case=TRUE;
  d->find_replace->scan_fwd=FALSE;d->find_replace->scan_sel_text=FALSE;d->find_replace->whole_labels=FALSE;
  if(mode==1){d->find_replace->match_case=FALSE;d->find_replace->whole_labels=TRUE;col=12;}
  if(mode==2){d->find_replace->whole_labels=TRUE;col=21;}
  if(mode==3){sc|=SCF_SHIFT;d->find_replace->scan_fwd=TRUE;d->cur_col=21;col=16;}
  if(mode==4){StrCpy(d->find_replace->find_text,"dog");col=0;}
  if(mode==5){last->type|=DOCET_SEL;d->find_replace->scan_sel_text=TRUE;want=last;col=0;}
  if(mode==6){first->de_flags|=DOCEF_FILTER_SKIP;want=last;col=0;}
  if(mode==7)DocLock(d);
  if(mode==8 || mode==9) {sc|=SCF_ALT;col=0;if(mode==9)sc|=SCF_SHIFT;}
  MemCpy(&saved,d->find_replace,sizeof(CEdFindText));
  if(mode<8)saved.scan_fwd=!(sc&SCF_SHIFT);
  StrCpy(keydev.desc,"unset");DocPutKey(d,0,sc);
  fn_positions[mode*3]=d->cur_entry==last;
  fn_positions[mode*3+1]=d->cur_col;fn_positions[mode*3+2]=d->find_replace->scan_fwd;
  if(d->cur_entry==want && d->cur_col==col)m|=1;
  if(!MemCmp(&saved,d->find_replace,sizeof(CEdFindText)))m|=2;
  if(!StrCmp(first->tag,"cat scatter CAT cat_ cat") && !StrCmp(last->tag,"cat"))m|=4;
  if(Bt(&d->locked_flags,DOClf_LOCKED)==(mode==7))m|=8;
  if(DocPut==put && DocDisplay==display && DocBorder==border)m|=16;
  if(!StrCmp(keydev.desc,"unset"))m|=32;
  DocUnlock(d);DocDel(d);if(Fs->data_heap->used_u8s==before)m|=64;
  return m;
}
U0 FNCheck()
{
  I64 i,sc,actions[10],metadata[6],before,col;U8 *wanted,*s;
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;CDocEntry *entry;CEdFindText saved;
  MemSet(fn_positions,0,sizeof(fn_positions));
  for(i=0;i<10;i++)actions[i]=FNAction(i);
  for(i=0;i<6;i++) {
    before=Fs->data_heap->used_u8s;d=FNDoc("Keep");entry=d->cur_entry;col=d->cur_col;
    d->find_replace->scan_fwd=FALSE;MemCpy(&saved,d->find_replace,sizeof(CEdFindText));
    sc=SC_F3|SCF_KEY_DESC;wanted="Edit/Find Next";
    if(i&1){sc|=SCF_SHIFT;wanted="Edit/Find Last";}
    if(i==2 || i==3){sc|=SCF_ALT;wanted="unset";}
    if(i==4 || i==5){sc|=SCF_CTRL;wanted="Edit/Autocomplete Sym";if(i==5)wanted="Cmd /Src Code of Sym";}
    StrCpy(keydev.desc,"unset");DocPutKey(d,0,sc);metadata[i]=0;
    if(d->cur_entry==entry && d->cur_col==col)metadata[i]|=1;
    if(!MemCmp(&saved,d->find_replace,sizeof(CEdFindText)))metadata[i]|=2;
    if(!StrCmp(entry->tag,"Keep"))metadata[i]|=4;
    if(!Bt(&d->locked_flags,DOClf_LOCKED))metadata[i]|=8;
    if(DocPut==put && DocDisplay==display && DocBorder==border)metadata[i]|=16;
    if(!StrCmp(keydev.desc,wanted))metadata[i]|=32;
    DocDel(d);if(Fs->data_heap->used_u8s==before)metadata[i]|=64;
  }
  s=MStrPrint("EXPORT find-key-actions.bin %X %X\n",actions,sizeof(actions));FNLog(s);Free(s);
  s=MStrPrint("EXPORT find-key-metadata.bin %X %X\n",metadata,sizeof(metadata));FNLog(s);Free(s);
  s=MStrPrint("EXPORT find-key-positions.bin %X %X\n",fn_positions,sizeof(fn_positions));FNLog(s);Free(s);
  FNLog("DOC FIND KEYS DONE\n");Sleep(1000);
}
