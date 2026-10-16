U8 DMBase;
CDrv *DMDrive;
I64 DMChildDone,DMChildResult;
Bool DMBytes(U8 *data,I64 size,U8 *expected,I64 count)
{I64 i;if(!data||size!=count)return FALSE;for(i=0;i<count;i++)if(data[i]!=expected[i])return FALSE;return TRUE;}
Bool DMSetup(U8 letter)
{
 U8 path[4];path[0]=letter;path[1]=':';path[2]='/';path[3]=0;
 if(!Cd(path))return FALSE;
 DirMk("Probe");if(!Cd("Probe"))return FALSE;
 DirMk("DriveMap");if(!Cd("DriveMap"))return FALSE;
 DMBase=letter;DMDrive=Fs->cur_dv;
 return FileWrite("Seed.TXT","seed",4)>0;
}
U0 DMChild(U8 *unused)
{
 Bool changed=Cd("X:/Probe/DriveMap");
 U8 *name=FileNameAbs("Seed.TXT"),*data;I64 size;
 data=FileRead("Seed.TXT",&size);
 DMChildResult=changed&&Fs->cur_dv==DMDrive&&Drv2Let()=='X'&&name&&name[0]=='X'&&DMBytes(data,size,"seed",4);
 Free(name);Free(data);DMChildDone=1;
}
I64 DMContract(I64 mode)
{
 CDrv *saved[DRVS_NUM],*expected[DRVS_NUM],records[DRVS_NUM],local,*target=DMDrive,*lookup;
 CDrv *current=Fs->cur_dv;U8 letter='X',*directory=StrNew(Fs->cur_dir),*data=NULL,*name=NULL,*base;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 CDirEntry entry;CTask *child=NULL;
 I64 i,j,before=Fs->data_heap->used_u8s,m=0,index,size=0,end;
 Bool valid=TRUE,ok=FALSE,exact=TRUE,letters=TRUE,restored=TRUE;
 CDoc *output=DocNew("DriveMapLog.DD");Fs->put_doc=output;
 if(mode==1)letter='x';if(mode==2)letter='?';if(mode==3)letter='[';
 if(mode==5)letter=0;if(mode==6)letter=':';if(mode==7)letter='~';
 index=Let2Let(letter)-'A';valid=index>=0&&index<DRVS_NUM;
 MemSet(&local,0,sizeof(CDrv));local.dv_signature=DRV_SIGNATURE_VAL;local.drv_let='Z';
 if(mode==3)target=NULL;if(mode==5)target=&local;
 if(mode==13){target=&local;local.dv_signature=0;}
 if(mode==14){MemCpy(&local,DMDrive,sizeof(CDrv));target=&local;}
 lookup=target;if(mode==13)lookup=NULL;
 Sleep(100);Bool wm=Suspend(sys_winmgr_task);
 for(i=0;i<DRVS_NUM;i++) {
   saved[i]=*DMMapSlot(i);expected[i]=saved[i];
   MemCpy(&records[i],DMRecord(i),sizeof(CDrv));
 }
 if(valid)expected[index]=target;
 if(mode==4)ok=DrvMap(letter,&local)&&Let2Drv(letter)==&local;
 else ok=TRUE;
 ok=ok&&DrvMap(letter,target)==valid;
 if(valid)ok=ok&&*DMMapSlot(index)==target&&target->drv_let=='A'+index&&Let2Drv('A'+index,FALSE)==lookup;
 if(mode==5)ok=ok&&Let2Drv()==current&&Let2Drv(DMBase)==&local;
 base=MStrPrint("%c:/Probe/DriveMap",DMBase);
 if(mode==8||mode==14) {
   data=FileRead("X:/Probe/DriveMap/Seed.TXT",&size);ok=ok&&DMBytes(data,size,"seed",4);Free(data);
   MemSet(&entry,0,sizeof(CDirEntry));ok=ok&&FileFind("X:/Probe/DriveMap/Seed.TXT",&entry,FUF_JUST_FILES)&&entry.size==4;Free(entry.full_name);
 } else if(mode==9) {
   ok=ok&&FileWrite("X:/Probe/DriveMap/Write.TXT","mapped",6)>0;
   name=MStrPrint("%s/Write.TXT",base);data=FileRead(name,&size);ok=ok&&DMBytes(data,size,"mapped",6);Free(data);Free(name);
 } else if(mode==10) {
   ok=ok&&Cd("X:/Probe/DriveMap")&&Fs->cur_dv==DMDrive&&Drv2Let()=='X';
   name=FileNameAbs("Seed.TXT");ok=ok&&name&&StrCmp(name,"X:/Probe/DriveMap/Seed.TXT")==0;Free(name);
 } else if(mode==11) {
   ok=ok&&DirMk("X:/Probe/DriveMap/Sub")&&FileWrite("X:/Probe/DriveMap/Sub/Child.TXT","child",5)>0;
   name=MStrPrint("%s/Sub/Child.TXT",base);data=FileRead(name,&size);ok=ok&&DMBytes(data,size,"child",5);Free(data);Free(name);
 } else if(mode==12) {
   DMChildDone=0;DMChildResult=0;child=Spawn(&DMChild,NULL,"map child",,Fs);
   end=cnts.jiffies+2000;
   while(child&&TaskValidate(child)&&cnts.jiffies<end)Yield;
   ok=ok&&child&&!TaskValidate(child)&&DMChildDone&&DMChildResult;
   if(child&&TaskValidate(child))Kill(child);
 }
 if(ok)m|=1;
 for(i=0;i<DRVS_NUM;i++) {
   if(*DMMapSlot(i)!=expected[i])exact=FALSE;
   if(DMRecord(i)==target&&valid)records[i].drv_let='A'+index;
   if(DMRecord(i)->drv_let!=records[i].drv_let)letters=FALSE;
   if(mode<8||mode==13)for(j=0;j<sizeof(CDrv);j++)if(DMRecord(i)(U8 *)[j]!=(&records[i])(U8 *)[j])letters=FALSE;
 }
 if(exact)m|=2;if(letters)m|=4;
 //Restore mappings and letters; real file operations may legitimately update caches.
 for(i=0;i<DRVS_NUM;i++)*DMMapSlot(i)=saved[i];
 DMDrive->drv_let=DMBase;
 if(Fs->cur_dv!=current||StrCmp(Fs->cur_dir,directory))restored=Cd(base);
 Free(base);Fs->put_doc=put;DocDel(output);
 if(restored&&Fs->cur_dv==current&&!StrCmp(Fs->cur_dir,directory)&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=8;
 if(Fs->data_heap->used_u8s==before)m|=16;
 Suspend(sys_winmgr_task,wm);Free(directory);
 return m;
}
I64 DMCheck(I64 mode){I64 m=DMContract(mode);if(m!=31)throw('DrvMap',TRUE);return m;}
