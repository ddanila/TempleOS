U8 *fme_root,*fme_alpha,*fme_bravo,*fme_keep;
U8 fme_renamed[6];
Bool fme_rename_ok,fme_cancel_ok;
U0 FMELog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool FMEAt(CDoc *doc,U8 *path)
{
  CDocEntry *entry;CDirEntry *de;
  if(!doc || doc->desc!='FileMan')return FALSE;
  entry=doc->cur_entry;
  if(entry==doc || entry->type_u8!=DOCT_TREE && entry->type_u8!=DOCT_MENU_VAL)return FALSE;
  de=entry->user_data;
  return de && !StrCmp(de->full_name,path);
}
Bool FMEBytes(U8 *path,U8 *wanted,I64 length,U8 *save=NULL)
{
  I64 size;U8 *data=FileRead(path,&size);Bool okay;
  okay=data && size==length && !MemCmp(data,wanted,length);
  if(okay && save)MemCpy(save,data,length);
  Free(data);return okay;
}
U0 FMEObserve(CTask *caller)
{
  I64 phase=0;CDoc *doc,*menu;CDocEntry *entry;CTask *popup;
  U8 *s;Bool ready;
  while(phase<10) {
    doc=caller->display_doc;popup=caller->popup_task;menu=NULL;ready=FALSE;
    if(popup && TaskValidate(popup) && popup==sys_focus_task)menu=popup->display_doc;
    if(phase==5 || phase==7)ready=menu && menu->desc=='Menu';
    else if(phase==8 && menu && menu->desc=='Menu') {
      entry=menu->cur_entry;
      ready=entry!=menu && entry->type_u8==DOCT_BTTN && !StrCmp(entry->tag,"OKAY");
    } else if(caller==sys_focus_task && doc) {
      if(phase==0)ready=FMEAt(doc,fme_root);
      else if(phase==1)ready=FMEAt(doc,fme_alpha);
      else if(phase==2)ready=doc->desc=='Form';
      else if(phase==3) {
        ready=FMEAt(doc,fme_keep) && !FileFind(fme_alpha);
        if(ready) {
          fme_rename_ok=FMEBytes(fme_bravo,"alpha\n",6,fme_renamed);
        }
      } else if(phase==4)ready=FMEAt(doc,fme_bravo);
      else if(phase==6) {
        ready=FMEAt(doc,fme_bravo) && !popup;
        if(ready)fme_cancel_ok=FMEBytes(fme_bravo,"alpha\n",6);
      } else if(phase==9)ready=FMEAt(doc,fme_keep) && !FileFind(fme_bravo) && !popup;
    }
    if(ready) {
      s=MStrPrint("FILEMGR EDIT READY %d\n",phase);FMELog(s);Free(s);phase++;
    }
    Yield;
  }
}
U0 FMECheck(U8 *root)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CTask *popup=Fs->popup_task,*observer;
  U8 *old=DirCur,*cwd,*res,*s;I64 rows[11];
  if(IsDir(root))throw('Exists',TRUE);
  DirMk(root);Cd(root);FileWrite("Alpha.TXT","alpha\n",6);FileWrite("Keep.TXT","keep\n",5);
  fme_root=root;fme_alpha=MStrPrint("%s/Alpha.TXT",root);
  fme_bravo=MStrPrint("%s/Bravo.TXT",root);fme_keep=MStrPrint("%s/Keep.TXT",root);
  fme_rename_ok=fme_cancel_ok=FALSE;
  observer=Spawn(&FMEObserve,Fs,"FileMgr edit observer",-1,Fs,16384);
  res=FileMgr;
  while(TaskValidate(observer))Yield;
  rows[0]=res==NULL;rows[1]=fme_rename_ok;rows[2]=fme_cancel_ok;
  rows[3]=!FileFind(fme_alpha);rows[4]=!FileFind(fme_bravo);rows[5]=FMEBytes(fme_keep,"keep\n",5);
  rows[6]=DocPut==put;rows[7]=DocDisplay==display;rows[8]=DocBorder==border;
  rows[9]=Fs->popup_task==popup;cwd=DirCur;rows[10]=!StrCmp(cwd,root);Free(cwd);
  s=MStrPrint("EXPORT edit-rows.bin %X %X\n",rows,sizeof(rows));FMELog(s);Free(s);
  s=MStrPrint("EXPORT renamed.bin %X %X\n",fme_renamed,sizeof(fme_renamed));FMELog(s);Free(s);
  Cd(old);Free(old);Free(res);Free(fme_alpha);Free(fme_bravo);Free(fme_keep);
  FMELog("FILEMGR EDIT DONE\n");Sleep(1000);
}
