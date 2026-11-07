I64 pk_case,pk_seen;
Bool pk_done;
CDoc *pk_doc;
U8 *pk_root,*pk_nested,*pk_alpha;
U0 PKLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PKObserve(CTask *caller)
{
  CTask *popup;CDoc *doc;CDocEntry *entry;CDirEntry *de;
  I64 stage=0,count=3;U8 *wanted,*s;
  if(pk_case==1 || pk_case==3)count=2;
  while(!pk_done && stage<count) {
    if(!stage)wanted=pk_root;else if(stage==1)wanted=pk_nested;else wanted=pk_alpha;
    popup=caller->popup_task;
    if(popup && TaskValidate(popup) && popup==sys_focus_task) {
      doc=popup->display_doc;
      if(doc && doc->win_task==popup && doc->desc=='FileMan') {
        entry=doc->cur_entry;
        if(entry!=doc && (entry->type_u8==DOCT_TREE || entry->type_u8==DOCT_MENU_VAL)) {
          de=entry->user_data;
          if(de && !StrCmp(de->full_name,wanted)) {
            pk_seen|=1;if(!Bt(&pk_doc->locked_flags,DOClf_LOCKED))pk_seen|=2;
            s=MStrPrint("PICKER KEY READY %d %d\n",pk_case,stage);PKLog(s);Free(s);stage++;
          }
        }
      }
    }
    Yield;
  }
}
U0 PKCheck(U8 *root)
{
  U8 *old=DirCur,*cwd,*text,*wanted,*s,*desc;I64 i,sc,col,size,metadata[6],masks[5];
  CDoc *d,*put=DocPut,*display=DocDisplay,*border=DocBorder;CTask *popup=Fs->popup_task,*observer;
  CDocEntry *entry;Bool locked;
  pk_root=root;pk_nested=MStrPrint("%s/Nested",root);pk_alpha=MStrPrint("%s/Alpha.TXT",root);Cd(root);
  for(i=0;i<6;i++) {
    d=DocNew("PickerMetadata.DD");DocPrint(d,"Keep");DocTop(d);d->flags|=DOCF_DONT_SWAP_OUT;
    sc=SC_F4|SCF_KEY_DESC;desc="Cmd /Insert FileName";
    if(i&1) {sc|=SCF_SHIFT;desc="Cmd /Insert Directory Name";}
    if(i==2 || i==3) {sc|=SCF_ALT;desc="unset";}
    if(i==4 || i==5) {sc|=SCF_CTRL;desc="Edit/Autocomplete Sym";if(i==5)desc="Cmd /Src Code of Sym";}
    entry=d->cur_entry;col=d->cur_col;StrCpy(keydev.desc,"unset");DocPutKey(d,0,sc);
    text=DocScanLine(d,d->head.next);metadata[i]=0;
    if(!StrCmp(keydev.desc,desc))metadata[i]|=1;
    if(text && !StrCmp(text,"Keep") && d->cur_entry==entry && d->cur_col==col)metadata[i]|=2;
    if(!Bt(&d->locked_flags,DOClf_LOCKED))metadata[i]|=4;
    if(DocPut==put && DocDisplay==display && DocBorder==border && Fs->popup_task==popup)metadata[i]|=8;
    Free(text);DocDel(d);
  }
  for(pk_case=0;pk_case<5;pk_case++) {
    pk_doc=DocNew("PickerKeys.DD");DocPrint(pk_doc,"BeforeAfter");DocTop(pk_doc);pk_doc->cur_col=6;
    pk_doc->flags|=DOCF_NO_CURSOR|DOCF_DONT_SWAP_OUT;locked=pk_case==4;
    if(locked)DocLock(pk_doc);
    pk_done=FALSE;pk_seen=0;observer=Spawn(&PKObserve,Fs,"Picker key observer",-1,Fs,16384);
    sc=SC_F4;if(pk_case==1 || pk_case==3)sc|=SCF_SHIFT;
    StrCpy(keydev.desc,"unset");DocPutKey(pk_doc,0,sc);pk_done=TRUE;
    while(TaskValidate(observer))Yield;
    wanted="";if(pk_case==0 || pk_case==4)wanted=pk_alpha;else if(pk_case==1)wanted=pk_nested;
    s=MStrPrint("Before%sAfter",wanted);text=DocScanLine(pk_doc,pk_doc->head.next,&col);masks[pk_case]=0;
    if(text && !StrCmp(text,s))masks[pk_case]|=1;Free(text);Free(s);
    if(col==6+StrLen(wanted))masks[pk_case]|=2;
    if(Bt(&pk_doc->locked_flags,DOClf_LOCKED)==locked)masks[pk_case]|=4;
    if(DocPut==put && DocDisplay==display && DocBorder==border && Fs->popup_task==popup)masks[pk_case]|=8;
    cwd=DirCur;if(!StrCmp(cwd,root))masks[pk_case]|=16;Free(cwd);
    if(!StrCmp(keydev.desc,"unset"))masks[pk_case]|=32;
    if(pk_seen==3)masks[pk_case]|=64;
    text=DocSave(pk_doc,&size);s=MStrPrint("EXPORT picker-key-%d.bin %X %X\n",pk_case,text,size);PKLog(s);Free(s);
    s=MStrPrint("PICKER KEY RETURN %d\n",pk_case);PKLog(s);Free(s);Sleep(1000);
    Free(text);if(locked)DocUnlock(pk_doc);DocDel(pk_doc);
  }
  s=MStrPrint("EXPORT picker-key-metadata.bin %X %X\n",metadata,sizeof(metadata));PKLog(s);Free(s);
  s=MStrPrint("EXPORT picker-key-masks.bin %X %X\n",masks,sizeof(masks));PKLog(s);Free(s);
  Cd(old);Free(old);Free(pk_nested);Free(pk_alpha);PKLog("PICKER KEY DONE\n");Sleep(1000);
}
