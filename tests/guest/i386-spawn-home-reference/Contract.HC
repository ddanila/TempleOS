U8 *SPHome,*SPAway,*SPOther,*SPName;
CDrv *SPExpectedDrive;
CTask *SPExpectedParent;
I64 SPDone,SPResult,SPParentReady,SPParentRelease;
U8 SPActualDir[256],SPActualName[256];
Bool SPBytes(U8 *data,I64 size)
{return data&&size==4&&data[0]=='h'&&data[1]=='o'&&data[2]=='m'&&data[3]=='e';}
Bool SPSetup()
{
 I64 length;
 SPHome=FileNameAbs("~/");if(!SPHome)return FALSE;
 length=StrLen(SPHome);if(length>3&&SPHome[length-1]=='/')SPHome[length-1]=0;
 if(!Cd(SPHome))return FALSE;
 if(FileWrite("SpawnSeed.TXT","home",4)<=0)return FALSE;
 SPName=FileNameAbs("SpawnSeed.TXT");
 DirMk("SpawnAway");if(!Cd("SpawnAway"))return FALSE;
 SPAway=FileNameAbs(".");
 if(FileWrite("SpawnSeed.TXT","away",4)<=0)return FALSE;
 DirMk("Selected");if(!Cd("Selected"))return FALSE;
 SPOther=FileNameAbs(".");
 if(FileWrite("SpawnSeed.TXT","else",4)<=0)return FALSE;
 return Cd(SPAway);
}
U0 SPChild(U8 *unused)
{
 U8 *name=FileNameAbs("SpawnSeed.TXT"),*data;I64 size;
 SPResult=0;StrCpy(SPActualDir,Fs->cur_dir);if(name)StrCpy(SPActualName,name);
 if(Fs->cur_dv==SPExpectedDrive&&StrCmp(Fs->cur_dir,SPHome+2)==0)SPResult|=1;
 if(Fs->parent_task==SPExpectedParent)SPResult|=2;
 if(name&&!StrCmp(name,SPName))SPResult|=4;
 data=FileRead("SpawnSeed.TXT",&size);if(SPBytes(data,size))SPResult|=8;
 Free(name);Free(data);SPDone=1;
}
U0 SPParent(U8 *unused)
{
 SPParentReady=Cd(SPOther);
 while(!SPParentRelease)Yield;
}
Bool SPWait(CTask *task)
{
 I64 end=cnts.jiffies+3000;
 while(task&&TaskValidate(task)&&cnts.jiffies<end)Yield;
 if(task&&TaskValidate(task)){Kill(task);return FALSE;}
 return task!=NULL;
}
I64 SPContract(I64 mode)
{
 CTask *child=NULL,*selected=NULL,*parent=Fs;
 CDrv *current=Fs->cur_dv,*mapped=*SPMapSlot(*SPHome-'A'),local;
 U8 *directory=Fs->cur_dir,old_letter=mapped->drv_let;
 CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
 I64 before=Fs->data_heap->used_u8s,m=0,end;
 Bool spawned=FALSE,retired=FALSE,dormant=TRUE;
 SPDone=SPResult=SPParentReady=SPParentRelease=0;
 SPExpectedDrive=mapped;
 if(mode==1)parent=Gs->seth_task;
 if(mode==2) {
   selected=Spawn(&SPParent,NULL,"Selected parent",-1,Fs);
   end=cnts.jiffies+3000;while(!SPParentReady&&cnts.jiffies<end)Yield;
   parent=selected;
 }
 if(mode==4) {
   MemCpy(&local,mapped,sizeof(CDrv));DrvMap(*SPHome,&local);SPExpectedDrive=&local;
 }
 if(mode==5) {MemSet(&local,0,sizeof(CDrv));Fs->cur_dv=&local;}
 if(mode==6)Fs->cur_dir=NULL;
 SPExpectedParent=parent;
 try {
   if(mode==1)child=Spawn(&SPChild,NULL,"Home child");
   else if(mode==3)child=Spawn(&SPChild,NULL,"Home dormant",-1,parent,,0);
   else child=Spawn(&SPChild,NULL,"Home child",-1,parent);
   spawned=child!=NULL;
 } catch {Fs->catch_except=TRUE;}
 Fs->cur_dv=current;Fs->cur_dir=directory;
 if(mode==3&&child) {
   dormant=child->cur_dv==SPExpectedDrive&&!StrCmp(child->cur_dir,SPHome+2)&&!SPDone;
   TaskQueIns(child);
 }
 if(child)retired=SPWait(child);
 SPParentRelease=1;if(selected&&!SPWait(selected))retired=FALSE;
 if(spawned&&dormant&&(mode!=2||SPParentReady))m|=1;
 if(SPDone&&SPResult==15)m|=2;
 if(Fs->cur_dv==current&&Fs->cur_dir==directory&&DocPut==put&&DocDisplay==display&&DocBorder==border)m|=4;
 if(Fs->data_heap->used_u8s==before)m|=8;
 if(retired&&SPDone)m|=16;
 *SPMapSlot(*SPHome-'A')=mapped;mapped->drv_let=old_letter;
 if(*SPMapSlot(*SPHome-'A')==mapped&&mapped->drv_let==old_letter)m|=32;
 return m;
}
I64 SPCheck(I64 mode){I64 m=SPContract(mode);if(m!=63)throw('SpnHome',TRUE);return m;}
