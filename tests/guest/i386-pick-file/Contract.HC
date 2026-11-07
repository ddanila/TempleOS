I64 pf_case;
U8 *pf_root,*pf_nested,*pf_alpha,*pf_marker;
U0 PFLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PFObserve(CTask *caller)
{
  CTask *popup;CDoc *doc;CDocEntry *entry;CDirEntry *de;
  I64 stage=0,count=3;U8 *wanted,*s;
  if(pf_case==1)count=2;else if(pf_case==2)count=1;
  while(stage<count) {
    if(pf_case==1 || pf_case==2) {
      if(!stage)wanted=pf_nested;else wanted=pf_marker;
    } else {
      if(!stage)wanted=pf_root;
      else if(stage==1)wanted=pf_nested;
      else wanted=pf_alpha;
    }
    popup=caller->popup_task;
    if(popup && TaskValidate(popup) && popup==sys_focus_task) {
      doc=popup->display_doc;
      if(doc && doc->win_task==popup && doc->desc=='FileMan') {
        entry=doc->cur_entry;
        if(entry!=doc && (entry->type_u8==DOCT_TREE || entry->type_u8==DOCT_MENU_VAL)) {
          de=entry->user_data;
          if(de && !StrCmp(de->full_name,wanted)) {
            s=MStrPrint("PICK FILE READY %d %d\n",pf_case,stage);PFLog(s);Free(s);stage++;
          }
        }
      }
    }
    Yield;
  }
}
U0 PFCheck(U8 *root)
{
  U8 *old_dir=DirCur,*res,*cwd,*s,*wanted;
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *old_popup=Fs->popup_task,*observer;
  I64 masks[5];
  pf_root=root;pf_nested=MStrPrint("%s/Nested",root);
  pf_alpha=MStrPrint("%s/Alpha.TXT",root);pf_marker=MStrPrint("%s/Nested/Marker.TXT",root);
  Cd(root);
  for(pf_case=0;pf_case<5;pf_case++) {
    observer=Spawn(&PFObserve,Fs,"File picker observer",-1,Fs,16384);
    if(pf_case==4)res=PopUpPickDir(root);
    else if(pf_case==1 || pf_case==2)res=PopUpPickFile(pf_nested);
    else res=PopUpPickFile;
    while(TaskValidate(observer))Yield;
    wanted="";
    if(!pf_case)wanted=pf_alpha;
    else if(pf_case==1)wanted=pf_marker;
    else if(pf_case==4)wanted=root;
    masks[pf_case]=0;
    if(res)masks[pf_case]|=1;
    if(res && !StrCmp(res,wanted))masks[pf_case]|=2;
    if(DocPut==put)masks[pf_case]|=4;
    if(DocDisplay==display)masks[pf_case]|=8;
    if(DocBorder==border)masks[pf_case]|=16;
    if(Fs->popup_task==old_popup)masks[pf_case]|=32;
    cwd=DirCur;if(!StrCmp(cwd,root))masks[pf_case]|=64;Free(cwd);
    if(res && MHeapCtrl(res)->mem_task==Fs)masks[pf_case]|=128;
    s=MStrPrint("EXPORT selected%d.TXT %X %X\n",pf_case,res,StrLen(res)+1);PFLog(s);Free(s);
    s=MStrPrint("PICK FILE RETURN %d\n",pf_case);PFLog(s);Free(s);
    Sleep(1000);Free(res);
  }
  s=MStrPrint("EXPORT masks.bin %X %X\n",masks,sizeof(masks));PFLog(s);Free(s);
  Cd(old_dir);Free(old_dir);Free(pf_nested);Free(pf_alpha);Free(pf_marker);
  PFLog("PICK FILE DONE\n");Sleep(1000);
}
