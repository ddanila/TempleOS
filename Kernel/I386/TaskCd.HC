Bool I386TaskCdExists(CI386RedSea *volume,U8 *absolute)
{
  CI386RedSeaEntry entry;
  Bool result=FALSE;
  if(!volume || !volume->io || !I386RedSeaBegin(volume)) return FALSE;
  if(I386RedSeaResolve(volume,volume->root,absolute+2,&entry)==1 && entry.attr&0x10) result=TRUE;
  if(!I386RedSeaEnd(volume)) result=FALSE;
  return result;
}
Bool I386TaskCd(U8 *dirname,Bool make_dirs)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CI386Heap *heap;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume;
  U8 *buffer=0,*mapped=0,*cursor,*component,*clean=0;
  I64 capacity=8,length=3,i,count,old,drive,ch;
  Bool result=FALSE,root=FALSE;
  if(dirname && !*dirname) {I386IrqRestore(flags);return TRUE;}
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(!state) goto task_cd_done;
  heap=state->heap;
  if(!dirname) dirname=paths.home_dir;
  if(!dirname) goto task_cd_release;
  for(i=0;dirname[i];i++) capacity++;
  for(i=0;paths.cur_dir[i];i++) capacity++;
  for(i=0;paths.home_dir && paths.home_dir[i];i++)capacity++;
  if(capacity>0x7FFFFFFF) goto task_cd_release;
  buffer=I386HeapAlloc(heap,capacity,TRUE);
  mapped=I386FileNameAbs(heap,&paths,dirname);
  if(!buffer || !mapped) goto task_cd_release;
  drive=mapped[0]; volume=volumes->letter[drive-'A'];
  if(!volume || !volume->io) goto task_cd_release;
  cursor=dirname;
  if(cursor[0] && cursor[1]==':') {cursor+=2; if(drive!=paths.cur_drv) root=TRUE;}
  if(*cursor=='/' || !*cursor) {root=TRUE;if(*cursor=='/')cursor++;}
  buffer[0]=drive;buffer[1]=':';buffer[2]='/';
  if(!root) {for(i=1;paths.cur_dir[i];i++)buffer[length++]=paths.cur_dir[i];}
  buffer[length]=0;
  clean=I386HeapAlloc(heap,capacity,TRUE);if(!clean)goto task_cd_release;
  while(*cursor && (paths.white_space[*cursor>>5]>>(*cursor&31))&1)cursor++;
  count=0;while(ch=*cursor++) {
    if((paths.white_space[ch>>5]>>(ch&31))&1 || ch>=31)clean[count++]=ch;
  }
  while(count && (paths.white_space[clean[count-1]>>5]>>(clean[count-1]&31))&1)count--;
  clean[count]=0;cursor=clean;result=TRUE;
  while(*cursor && result) {
    component=cursor;count=0;while(*cursor && *cursor!='/'){cursor++;count++;}
    if(*cursor=='/')cursor++;
    if(!count) {length=3;buffer[length]=0;}
    else if(count==1 && component[0]=='~') {
      if(!paths.home_dir) {result=FALSE;break;}
      length=0;while(paths.home_dir[length]) {buffer[length]=paths.home_dir[length];length++;}
      buffer[length]=0;drive=buffer[0];volume=volumes->letter[drive-'A'];
      if(!volume || !I386TaskCdExists(volume,buffer))result=FALSE;
    }
    else if(count==1 && component[0]=='.') {}
    else if(count==2 && component[0]=='.' && component[1]=='.') {
      while(length>3 && buffer[length-1]!='/')length--;
      if(length>3)length--;buffer[length]=0;
    } else {
      old=length;if(length>3)buffer[length++]='/';
      for(i=0;i<count;i++)buffer[length++]=component[i];buffer[length]=0;
      if(!I386TaskCdExists(volume,buffer)) {
        if(!make_dirs || !I386TaskDirMk(buffer,0) || !I386TaskCdExists(volume,buffer)) {
          length=old;buffer[length]=0;result=FALSE;
        }
      }
    }
  }
  if(!I386TaskFilesRelease(state)) {state=0;result=FALSE;goto task_cd_free;}
  state=0;
  if(!I386TaskFilesSet(task,buffer+2,drive))result=FALSE;
  goto task_cd_free;
task_cd_release:
  I386TaskFilesRelease(state);
task_cd_free:
  if(clean)I386HeapFree(heap,clean);
  if(mapped)I386HeapFree(heap,mapped);
  if(buffer)I386HeapFree(heap,buffer);
task_cd_done:
  I386IrqRestore(flags);return result;
}
