Bool fcp_tree;
U8 *fcp_root,*fcp_dest,*fcp_source,*fcp_keep,*fcp_copy;
U8 *fcp_empty,*fcp_nested,*fcp_payload,*fcp_copy_empty,*fcp_expected;
U8 fcp_source_bytes[6],fcp_copy_bytes[6];
I64 fcp_clipmask;
U0 FCPLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
Bool FCPAt(CDoc *doc,U8 *path)
{
  CDocEntry *entry;CDirEntry *de;
  if(!doc || doc->desc!='FileMan')return FALSE;
  entry=doc->cur_entry;
  if(entry==doc || entry->type_u8!=DOCT_TREE && entry->type_u8!=DOCT_MENU_VAL)return FALSE;
  de=entry->user_data;
  return de && !StrCmp(de->full_name,path);
}
I64 FCPMask(CDoc *doc,Bool selected=FALSE)
{
  CDocEntry *entry;CDirEntry *de;I64 mask=0,bit;
  for(entry=doc->head.next;entry!=doc;entry=entry->next) {
    if((!selected || entry->type&DOCET_SEL) &&
        (entry->type_u8==DOCT_TREE || entry->type_u8==DOCT_MENU_VAL)) {
      de=entry->user_data;bit=0;
      if(!de)return -1;
      if(!StrCmp(de->full_name,fcp_source))bit=1;
      else if(fcp_tree) {
        if(!StrCmp(de->full_name,fcp_empty))bit=2;
        else if(!StrCmp(de->full_name,fcp_nested))bit=4;
        else if(!StrCmp(de->full_name,fcp_payload))bit=8;
      }
      if(!bit || mask&bit)return -1;
      mask|=bit;
    }
  }
  return mask;
}
Bool FCPBytes(U8 *path,U8 *wanted,I64 length,U8 *save=NULL)
{
  I64 size;U8 *data=FileRead(path,&size);Bool okay;
  okay=data && size==length && !MemCmp(data,wanted,length);
  if(okay && save)MemCpy(save,data,length);
  Free(data);return okay;
}
U0 FCPObserve(CTask *caller)
{
  I64 phase=0,total=8,want=1,mask;CDoc *doc;U8 *s;Bool ready;
  if(fcp_tree){total=5;want=15;}
  while(phase<total) {
    doc=caller->display_doc;ready=FALSE;
    if(caller==sys_focus_task && doc && doc->desc=='FileMan') {
      if(!phase)ready=FCPAt(doc,fcp_root);
      else if(fcp_tree) {
        if(phase==1)ready=FCPAt(doc,fcp_source);
        else if(phase==2)ready=FCPAt(doc,fcp_dest) && FCPMask(doc,TRUE)==want;
        else if(phase==3) {
          mask=FCPMask(sys_clip_doc);
          ready=mask==want;if(ready)fcp_clipmask=mask;
        } else if(phase==4)ready=FCPAt(doc,fcp_dest) && FileFind(fcp_copy) && sys_clip_doc->head.next==sys_clip_doc;
      } else {
        if(phase==1 || phase==6)ready=FCPAt(doc,fcp_dest);
        else if(phase==2 || phase==5)ready=FCPAt(doc,fcp_source);
        else if(phase==3)ready=FCPAt(doc,fcp_keep) && FCPMask(doc,TRUE)==want;
        else if(phase==4) {
          mask=FCPMask(sys_clip_doc);
          ready=mask==want;if(ready)fcp_clipmask=mask;
        } else if(phase==7)ready=FCPAt(doc,fcp_dest) && FileFind(fcp_copy) && sys_clip_doc->head.next==sys_clip_doc;
      }
    }
    if(ready) {
      s=MStrPrint("FILEMGR CLIP READY %d\n",phase);FCPLog(s);Free(s);phase++;
    }
    Yield;
  }
}
U0 FCPCheck(U8 *root,Bool tree=FALSE)
{
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder,*clip=sys_clip_doc;
  CTask *popup=Fs->popup_task,*observer;
  U8 *old=DirCur,*cwd,*res,*s,*source_data;I64 rows[13],want=1;
  if(IsDir(root))throw('Exists',TRUE);
  fcp_tree=tree;fcp_root=root;fcp_clipmask=0;
  DirMk(root);Cd(root);DirMk("Dest");FileWrite("Keep.TXT","keep\n",5);
  fcp_dest=MStrPrint("%s/Dest",root);fcp_keep=MStrPrint("%s/Keep.TXT",root);
  fcp_empty=fcp_nested=fcp_payload=fcp_copy_empty=NULL;
  if(tree) {
    want=15;fcp_expected="\x00\x01\x7F\x80\xFE\xFF";
    DirMk("Alpha");DirMk("Alpha/Empty");DirMk("Alpha/Nested");
    FileWrite("Alpha/Nested/Payload.BIN",fcp_expected,6);
    fcp_source=MStrPrint("%s/Alpha",root);fcp_empty=MStrPrint("%s/Alpha/Empty",root);
    fcp_nested=MStrPrint("%s/Alpha/Nested",root);fcp_payload=MStrPrint("%s/Alpha/Nested/Payload.BIN",root);
    fcp_copy=MStrPrint("%s/Dest/Alpha/Nested/Payload.BIN",root);
    fcp_copy_empty=MStrPrint("%s/Dest/Alpha/Empty",root);source_data=fcp_payload;
  } else {
    fcp_expected="alpha\n";FileWrite("Alpha.TXT",fcp_expected,6);
    fcp_source=MStrPrint("%s/Alpha.TXT",root);fcp_copy=MStrPrint("%s/Dest/Alpha.TXT",root);source_data=fcp_source;
  }
  observer=Spawn(&FCPObserve,Fs,"FileMgr clipboard observer",-1,Fs,16384);
  res=FileMgr;
  while(TaskValidate(observer))Yield;
  rows[0]=res==NULL;rows[1]=FCPBytes(source_data,fcp_expected,6,fcp_source_bytes);
  rows[2]=FCPBytes(fcp_copy,fcp_expected,6,fcp_copy_bytes);rows[3]=FCPBytes(fcp_keep,"keep\n",5);
  rows[4]=fcp_clipmask==want;rows[5]=sys_clip_doc->head.next==sys_clip_doc;
  rows[6]=DocPut==put;rows[7]=DocDisplay==display;rows[8]=DocBorder==border;
  rows[9]=Fs->popup_task==popup;cwd=DirCur;rows[10]=!StrCmp(cwd,root);Free(cwd);
  rows[11]=sys_clip_doc==clip;
  if(tree)rows[12]=IsDir(fcp_empty)&&IsDir(fcp_copy_empty);else rows[12]=!IsDir(fcp_copy);
  s=MStrPrint("EXPORT clip-rows.bin %X %X\n",rows,sizeof(rows));FCPLog(s);Free(s);
  s=MStrPrint("EXPORT clip-mask.bin %X %X\n",&fcp_clipmask,sizeof(fcp_clipmask));FCPLog(s);Free(s);
  s=MStrPrint("EXPORT source.bin %X %X\n",fcp_source_bytes,6);FCPLog(s);Free(s);
  s=MStrPrint("EXPORT copied.bin %X %X\n",fcp_copy_bytes,6);FCPLog(s);Free(s);
  Cd(old);Free(old);Free(res);Free(fcp_dest);Free(fcp_source);Free(fcp_keep);Free(fcp_copy);
  Free(fcp_empty);Free(fcp_nested);Free(fcp_payload);Free(fcp_copy_empty);
  FCPLog("FILEMGR CLIP DONE\n");Sleep(1000);
}
