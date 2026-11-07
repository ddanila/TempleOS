U8 *fmw_root,*fmw_made,*fmw_cancelled;
U0 FMWLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool FMWAtRoot(CDoc *doc)
{
  CDocEntry *entry;CDirEntry *de;
  if(!doc || doc->desc!='FileMan')return FALSE;
  entry=doc->cur_entry;
  if(entry==doc || entry->type_u8!=DOCT_TREE)return FALSE;
  de=entry->user_data;
  return de && !StrCmp(de->full_name,fmw_root);
}
U0 FMWObserve(CTask *caller)
{
  I64 phase=0;CDoc *doc;U8 *s;Bool ready;
  while(phase<5) {
    doc=caller->display_doc;ready=FALSE;
    if(caller==sys_focus_task && doc) {
      if(phase==0)ready=FMWAtRoot(doc);
      else if(phase==1 || phase==3)ready=doc->desc=='Form';
      else if(phase==2)ready=FMWAtRoot(doc) && IsDir(fmw_made);
      else ready=FMWAtRoot(doc) && !IsDir(fmw_cancelled);
    }
    if(ready) {
      s=MStrPrint("FILEMGR READY %d\n",phase);FMWLog(s);Free(s);phase++;
    }
    Yield;
  }
}
U0 FMWCheck(U8 *root)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *popup=Fs->popup_task,*observer;
  U8 *old=DirCur,*cwd,*res,*s,*data;I64 rows[9],size;
  if(IsDir(root))throw('Exists',TRUE);
  DirMk(root);Cd(root);FileWrite("Keep.TXT","keep\n",5);
  fmw_root=root;fmw_made=MStrPrint("%s/Made",root);
  fmw_cancelled=MStrPrint("%s/Cancelled",root);
  observer=Spawn(&FMWObserve,Fs,"FileMgr observer",-1,Fs,16384);
  res=FileMgr;
  while(TaskValidate(observer))Yield;
  rows[0]=res==NULL;rows[1]=IsDir(fmw_made);rows[2]=!IsDir(fmw_cancelled);
  rows[3]=DocPut==put;rows[4]=DocDisplay==display;rows[5]=DocBorder==border;
  rows[6]=Fs->popup_task==popup;cwd=DirCur;rows[7]=!StrCmp(cwd,root);Free(cwd);
  data=FileRead("Keep.TXT",&size);rows[8]=size==5 && !MemCmp(data,"keep\n",5);Free(data);
  s=MStrPrint("EXPORT mkdir-rows.bin %X %X\n",rows,sizeof(rows));FMWLog(s);Free(s);
  Cd(old);Free(old);Free(res);Free(fmw_made);Free(fmw_cancelled);
  FMWLog("FILEMGR MKDIR DONE\n");Sleep(1000);
}
