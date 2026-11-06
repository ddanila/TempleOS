I64 pd_case;
U8 *pd_expected;
U0 PDLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 PDObserve(CTask *caller)
{
  CTask *popup;CDoc *doc;CDocEntry *entry;CDirEntry *de;U8 *s;
  while(TRUE) {
    popup=caller->popup_task;
    if(popup && TaskValidate(popup) && popup==sys_focus_task) {
      doc=popup->display_doc;
      if(doc && doc->win_task==popup && doc->desc=='FileMan') {
        entry=doc->cur_entry;
        if(entry!=doc && entry->type_u8==DOCT_TREE) {
          de=entry->user_data;
          if(de && !StrCmp(de->full_name,pd_expected)) {
            s=MStrPrint("PICK DIR READY %d\n",pd_case);PDLog(s);Free(s);
            return;
          }
        }
      }
    }
    Yield;
  }
}
U0 PDCheck(U8 *root)
{
  U8 *old_dir=DirCur,*nested=MStrPrint("%s/Nested",root),*res,*cwd,*s;
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *old_popup=Fs->popup_task,*observer;
  I64 masks[3];
  Cd(root);
  for(pd_case=0;pd_case<3;pd_case++) {
    if(pd_case)pd_expected=nested;else pd_expected=root;
    observer=Spawn(&PDObserve,Fs,"Picker observer",-1,Fs,16384);
    if(pd_case)res=PopUpPickDir(nested);
    else res=PopUpPickDir;
    while(TaskValidate(observer))Yield;
    masks[pd_case]=0;
    if(res) masks[pd_case]|=1;
    if(pd_case==2) {if(res && !*res)masks[pd_case]|=2;}
    else if(res && !StrCmp(res,pd_expected))masks[pd_case]|=2;
    if(DocPut==put)masks[pd_case]|=4;
    if(DocDisplay==display)masks[pd_case]|=8;
    if(DocBorder==border)masks[pd_case]|=16;
    if(Fs->popup_task==old_popup)masks[pd_case]|=32;
    cwd=DirCur;if(!StrCmp(cwd,root))masks[pd_case]|=64;Free(cwd);
    s=MStrPrint("EXPORT selected%d.TXT %X %X\n",pd_case,res,StrLen(res)+1);PDLog(s);Free(s);
    // Allow the host export collector to copy the returned name before freeing it.
    s=MStrPrint("PICK DIR RETURN %d\n",pd_case);PDLog(s);Free(s);
    Sleep(1000);Free(res);
  }
  s=MStrPrint("EXPORT masks.bin %X %X\n",masks,sizeof(masks));PDLog(s);Free(s);
  Cd(old_dir);Free(old_dir);Free(nested);
  PDLog("PICK DIR DONE\n");Sleep(1000);
}
