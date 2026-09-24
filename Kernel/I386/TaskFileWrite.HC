#include "/Kernel/I386/TaskFileRead.HH"
#include "/Kernel/I386/Cpu.HH"
Bool I386TaskFileWrite(U8 *filename,U8 *buffer,I64 size,I64 attr=0)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume;
  CI386RedSeaEntry parent,existing;
  U8 *absolute=0,*path,*leaf,*cursor;
  I64 drive,status;
  Bool result=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && size>=0 && (!size || buffer)) {
    absolute=I386FileNameAbs(state->heap,&paths,filename);
    if(absolute) {
      drive=absolute[0]; if('a'<=drive<='z') drive-=32;
      if('A'<=drive<='Z' && absolute[1]==':' && absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; path=absolute+2;
        leaf=path; cursor=path;
        while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
        if(volume && volume->io && *leaf && I386RedSeaBegin(volume)) {
          if(leaf==path+1) parent.block=volume->root;
          else {
            leaf[-1]=0;
            status=I386RedSeaResolve(volume,volume->root,path,&parent);
            leaf[-1]='/';
            if(status!=1) {
              leaf[-1]=0;
              KernelLog("FILE WRITE parent resolve error "); KernelLog(path);
              KernelLog(" | "); KernelLog(leaf); KernelLog("\n");
              leaf[-1]='/'; parent.block=0;
            } else if(!(parent.attr&0x10)) {
              KernelLog("FILE WRITE parent type error\n"); parent.block=0;
            }
          }
          if(parent.block) {
            status=I386RedSeaFind(volume,parent.block,leaf,&existing);
            if(status==1)
              status=I386RedSeaReplace(volume,parent.block,leaf,buffer,size,0);
            else if(!status)
              status=I386RedSeaCreate(volume,parent.block,leaf,buffer,size,0);
            if(status!=1) KernelLog("FILE WRITE mutation error\n");
            result=status==1;
          }
          if(!I386RedSeaEnd(volume)) {
            KernelLog("FILE WRITE end error\n"); result=FALSE;
          }
        }
      }
      I386HeapFree(state->heap,absolute);
    }
  }
  if(state && !I386TaskFilesRelease(state)) {
    KernelLog("FILE WRITE release error\n"); result=FALSE;
  }
  I386IrqRestore(flags); return result;
}

Bool I386TaskFileDelete(U8 *filename)
{//Delete one regular file resolved through the current task's path context.
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume;
  CI386RedSeaEntry parent;
  U8 *absolute=0,*path,*leaf,*cursor;
  I64 drive,status;
  Bool result=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && filename) {
    absolute=I386FileNameAbs(state->heap,&paths,filename);
    if(absolute) {
      drive=absolute[0]; if('a'<=drive<='z') drive-=32;
      if('A'<=drive<='Z' && absolute[1]==':' && absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; path=absolute+2;
        leaf=path; cursor=path;
        while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
        if(volume && volume->io && *leaf && I386RedSeaBegin(volume)) {
          if(leaf==path+1) parent.block=volume->root;
          else {
            leaf[-1]=0;
            status=I386RedSeaResolve(volume,volume->root,path,&parent);
            leaf[-1]='/';
            if(status!=1 || !(parent.attr&0x10)) parent.block=0;
          }
          if(parent.block) result=I386RedSeaDelete(volume,parent.block,leaf)==1;
          if(!I386RedSeaEnd(volume)) result=FALSE;
        }
      }
      I386HeapFree(state->heap,absolute);
    }
  }
  if(state && !I386TaskFilesRelease(state)) result=FALSE;
  I386IrqRestore(flags); return result;
}

Bool I386TaskDirDelete(U8 *filename)
{//Delete one empty non-root directory through the current task's path context.
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume;
  CI386RedSeaEntry parent;
  U8 *absolute=0,*path,*leaf,*cursor;
  I64 drive,status;
  Bool result=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && filename) {
    absolute=I386FileNameAbs(state->heap,&paths,filename);
    if(absolute) {
      drive=absolute[0]; if('a'<=drive<='z') drive-=32;
      if('A'<=drive<='Z' && absolute[1]==':' && absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; path=absolute+2;
        leaf=path; cursor=path;
        while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
        if(volume && volume->io && *leaf && I386RedSeaBegin(volume)) {
          if(leaf==path+1) parent.block=volume->root;
          else {
            leaf[-1]=0;
            status=I386RedSeaResolve(volume,volume->root,path,&parent);
            leaf[-1]='/';
            if(status!=1 || !(parent.attr&0x10)) parent.block=0;
          }
          if(parent.block) result=I386RedSeaDirDelete(volume,parent.block,leaf)==1;
          if(!I386RedSeaEnd(volume)) result=FALSE;
        }
      }
      I386HeapFree(state->heap,absolute);
    }
  }
  if(state && !I386TaskFilesRelease(state)) result=FALSE;
  I386IrqRestore(flags); return result;
}

Bool I386TaskFileRename(U8 *old_filename,U8 *new_filename)
{//Atomically rename one file or directory within its existing directory.
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume,*new_volume;
  CI386RedSeaEntry parent,new_parent;
  U8 *old_absolute=0,*new_absolute=0,*path,*new_path,*leaf,*new_leaf,*cursor;
  I64 drive,new_drive,status;
  Bool result=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && old_filename && new_filename) {
    old_absolute=I386FileNameAbs(state->heap,&paths,old_filename);
    new_absolute=I386FileNameAbs(state->heap,&paths,new_filename);
    if(old_absolute && new_absolute) {
      drive=old_absolute[0]; if('a'<=drive<='z') drive-=32;
      new_drive=new_absolute[0]; if('a'<=new_drive<='z') new_drive-=32;
      if('A'<=drive<='Z' && 'A'<=new_drive<='Z' && drive==new_drive &&
         old_absolute[1]==':' && old_absolute[2]=='/' &&
         new_absolute[1]==':' && new_absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; new_volume=volumes->letter[new_drive-'A'];
        path=old_absolute+2; new_path=new_absolute+2;
        leaf=path; cursor=path;
        while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
        new_leaf=new_path; cursor=new_path;
        while(*cursor) { if(*cursor=='/') new_leaf=cursor+1; cursor++; }
        if(volume && volume==new_volume && volume->io && *leaf && *new_leaf &&
           I386RedSeaBegin(volume)) {
          if(leaf==path+1) parent.block=volume->root;
          else {
            leaf[-1]=0; status=I386RedSeaResolve(volume,volume->root,path,&parent);
            leaf[-1]='/'; if(status!=1 || !(parent.attr&0x10)) parent.block=0;
          }
          if(new_leaf==new_path+1) new_parent.block=volume->root;
          else {
            new_leaf[-1]=0;
            status=I386RedSeaResolve(volume,volume->root,new_path,&new_parent);
            new_leaf[-1]='/';
            if(status!=1 || !(new_parent.attr&0x10)) new_parent.block=0;
          }
          if(parent.block && parent.block==new_parent.block)
            result=I386RedSeaRename(volume,parent.block,leaf,new_leaf)==1;
          if(!I386RedSeaEnd(volume)) result=FALSE;
        }
      }
    }
    if(old_absolute) I386HeapFree(state->heap,old_absolute);
    if(new_absolute) I386HeapFree(state->heap,new_absolute);
  }
  if(state && !I386TaskFilesRelease(state)) result=FALSE;
  I386IrqRestore(flags); return result;
}

Bool I386TaskFileMoveStage(U8 *old_filename,U8 *new_filename,I64 fail_stage)
{//Copy-publish-delete one regular file across directories on the same volume.
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume,*new_volume;
  CI386RedSeaEntry parent,new_parent,source,collision;
  U8 *old_absolute=0,*new_absolute=0,*buffer=0;
  U8 *path,*new_path,*leaf,*new_leaf,*cursor;
  I64 drive,new_drive,status,size=0,rollback;
  Bool result=FALSE,source_root=FALSE,destination_root=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && old_filename && new_filename) {
    old_absolute=I386FileNameAbs(state->heap,&paths,old_filename);
    new_absolute=I386FileNameAbs(state->heap,&paths,new_filename);
    if(old_absolute && new_absolute) {
      drive=old_absolute[0]; if('a'<=drive<='z') drive-=32;
      new_drive=new_absolute[0]; if('a'<=new_drive<='z') new_drive-=32;
      if('A'<=drive<='Z' && 'A'<=new_drive<='Z' && drive==new_drive &&
         old_absolute[1]==':' && old_absolute[2]=='/' &&
         new_absolute[1]==':' && new_absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; new_volume=volumes->letter[new_drive-'A'];
        path=old_absolute+2; new_path=new_absolute+2;
        leaf=path; cursor=path;
        while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
        new_leaf=new_path; cursor=new_path;
        while(*cursor) { if(*cursor=='/') new_leaf=cursor+1; cursor++; }
        if(volume && volume==new_volume && volume->io && *leaf && *new_leaf &&
           I386RedSeaBegin(volume)) {
          if(leaf==path+1) { parent.block=volume->root; source_root=TRUE; }
          else {
            leaf[-1]=0; status=I386RedSeaResolve(volume,volume->root,path,&parent);
            leaf[-1]='/'; if(status!=1 || !(parent.attr&0x10)) parent.block=0;
          }
          if(new_leaf==new_path+1) { new_parent.block=volume->root; destination_root=TRUE; }
          else {
            new_leaf[-1]=0;
            status=I386RedSeaResolve(volume,volume->root,new_path,&new_parent);
            new_leaf[-1]='/';
            if(status!=1 || !(new_parent.attr&0x10)) new_parent.block=0;
          }
          if(parent.block && new_parent.block) {
            if(parent.block==new_parent.block)
              result=I386RedSeaRename(volume,parent.block,leaf,new_leaf)==1;
            else {
              status=I386RedSeaFind(volume,parent.block,leaf,&source);
              if(status==1 && !(source.attr&0x11) &&
                 I386RedSeaFind(volume,new_parent.block,new_leaf,&collision)==0) {
                size=source.size;
                if(fail_stage!=1 &&
                   (!size || (buffer=I386RedSeaReadAll(volume,state->heap,&source,&size)))) {
                  if(fail_stage==2) status=0;
                  else if(I386RedSeaMoveIntentSet(volume,parent.block,source_root,leaf,
                    new_parent.block,destination_root,new_leaf,&source)) {
                    status=I386RedSeaCreate(volume,new_parent.block,new_leaf,buffer,size,
                      source.datetime,source.attr);
                    if(status==1) {
                      if(source_root) parent.block=volume->root;
                      if(destination_root) new_parent.block=volume->root;
                      if(fail_stage==3) status=0;
                      else if(fail_stage==4) status=-1;
                      else status=I386RedSeaDelete(volume,parent.block,leaf);
                      if(status==1) {
                        if(I386RedSeaMoveIntentClear(volume)) result=TRUE;
                      } else {
                        rollback=I386RedSeaDelete(volume,new_parent.block,new_leaf);
                        if(rollback==1 && I386RedSeaValid(volume))
                          I386RedSeaMoveIntentClear(volume);
                      }
                    } else if(!status && I386RedSeaValid(volume))
                      I386RedSeaMoveIntentClear(volume);
                  }
                }
              }
            }
          }
          if(!I386RedSeaEnd(volume)) result=FALSE;
        }
      }
    }
    if(buffer) I386HeapFree(state->heap,buffer);
    if(old_absolute) I386HeapFree(state->heap,old_absolute);
    if(new_absolute) I386HeapFree(state->heap,new_absolute);
  }
  if(state && !I386TaskFilesRelease(state)) result=FALSE;
  I386IrqRestore(flags); return result;
}

Bool I386TaskFileMove(U8 *old_filename,U8 *new_filename)
{
  return I386TaskFileMoveStage(old_filename,new_filename,0);
}

Bool I386TaskFileMoveProbeRead(U8 *filename,Bool present)
{//Read through the public task path after releasing the configuration borrow.
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386Heap *heap=0;
  U8 *buffer;
  I64 size=0;
  Bool result;
  state=I386TaskFilesBorrow(I386TaskSelf,&paths,&volumes);
  if(state) { heap=state->heap; if(!I386TaskFilesRelease(state)) heap=0; }
  if(!heap) return FALSE;
  buffer=I386TaskFileRead(heap,filename,&size);
  if(!present) {
    if(buffer) I386HeapFree(heap,buffer);
    return !buffer;
  }
  result=buffer && size==4 && buffer[0]=='M' && buffer[1]=='O' &&
    buffer[2]=='V' && buffer[3]=='E';
  if(buffer) I386HeapFree(heap,buffer);
  return result;
}

Bool I386TaskFileMoveProbe()
{//Exercise failure recovery without publishing a test hook to native HolyC.
  U8 *source="C:/MoveProbeA/Source.HC",*destination="C:/MoveProbeB/Destination.HC";
  I64 stage;
  Bool ok=FALSE;
  I386TaskFileDelete(source); I386TaskFileDelete(destination);
  I386TaskDirDelete("C:/MoveProbeA"); I386TaskDirDelete("C:/MoveProbeB");
  if(!I386TaskDirMk("C:/MoveProbeA") || !I386TaskDirMk("C:/MoveProbeB") ||
     !I386TaskFileWrite(source,"MOVE",4)) goto done;
  for(stage=1;stage<=4;stage++) {
    if(I386TaskFileMoveStage(source,destination,stage) ||
       !I386TaskFileMoveProbeRead(source,TRUE) ||
       !I386TaskFileMoveProbeRead(destination,FALSE)) goto done;
  }
  if(!I386TaskFileMove(source,destination) ||
     !I386TaskFileMoveProbeRead(source,FALSE) ||
     !I386TaskFileMoveProbeRead(destination,TRUE)) goto done;
  ok=TRUE;
done:
  if(!I386TaskFileDelete(destination)) ok=FALSE;
  if(!I386TaskDirDelete("C:/MoveProbeA")) ok=FALSE;
  if(!I386TaskDirDelete("C:/MoveProbeB")) ok=FALSE;
  return ok;
}

Bool I386TaskFileMoveIoProbe(I64 operation,I64 fail_after)
{//Arm after fixture publication; operations 4/5 exercise replacement write/flush.
  U8 *source="C:/Probe/MoveIoSource.HC";
  U8 *destination="C:/Modules/MoveIoDestination.HC";
  U8 *replacement="C:/Probe/ReplaceIo.HC";
  I64 raw_operation=operation;
  Bool result,fired;
  if(operation==4) raw_operation=2;
  if(operation==5) raw_operation=3;
  if((operation<2 || operation>5) || fail_after<1 || fail_after>16) {
    KernelLog("FILE IO PROBE invalid\n"); return FALSE;
  }
  if(operation>=4) {
    I386TaskFileDelete(replacement);
    if(!I386TaskFileWrite(replacement,"OLD",3)) {
      KernelLog("FILE IO PROBE replace setup\n"); return FALSE;
    }
    I386RedSeaTaskFailArm(raw_operation,fail_after);
    result=I386TaskFileWrite(replacement,"NEW",3);
    if(result) KernelLog("FILE IO PROBE unexpected replace success\n");
    if(!i386_redsea_fail_fired) KernelLog("FILE IO PROBE not fired\n");
    fired=i386_redsea_fail_fired;
    I386RedSeaTaskFailArm(0,0);
    return !result && fired;
  }
  I386TaskFileDelete(source); I386TaskFileDelete(destination);
  if(!I386TaskFileWrite(source,"IO",2)) {
    KernelLog("FILE IO PROBE setup\n"); return FALSE;
  }
  I386RedSeaTaskFailArm(raw_operation,fail_after);
  result=I386TaskFileMove(source,destination);
  if(result) KernelLog("FILE IO PROBE unexpected success\n");
  if(!i386_redsea_fail_fired) KernelLog("FILE IO PROBE not fired\n");
  fired=i386_redsea_fail_fired;
  I386RedSeaTaskFailArm(0,0);
  return !result && fired;
}

I64 I386TaskDirList(U8 *filename,U8 *buffer,I64 capacity,I64 *entries=0)
{//Names in on-disk order, with '/' after directories and one name per line.
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume;
  CI386RedSeaEntry directory;
  U8 *absolute=0,*path,sector[512],*raw;
  I64 drive,status,size,index,needed=1,count=0,at=0;
  Bool ok=FALSE,is_dir;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && filename) {
    absolute=I386FileNameAbs(state->heap,&paths,filename);
    if(absolute) {
      drive=absolute[0]; if('a'<=drive<='z') drive-=32;
      if('A'<=drive<='Z' && absolute[1]==':' && absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; path=absolute+2;
        if(volume && volume->io && I386RedSeaBegin(volume)) {
          if(path[0]=='/' && !path[1]) {
            directory.block=volume->root; directory.attr=0x10;
          } else {
            status=I386RedSeaResolve(volume,volume->root,path,&directory);
            if(status!=1) directory.block=0;
          }
          if(directory.block && (directory.attr&0x10) &&
              I386RedSeaDirectory(volume,directory.block,sector,&size)) {
            ok=TRUE;
            for(index=0;index<size/64;index++) {
              if(!(index&7) && index &&
                  !I386RedSeaSectorRead(volume,directory.block+index/8,sector)) { ok=FALSE; break; }
              raw=sector+(index&7)*64;
              if(!raw[2]) break;
              if(!(raw[1]&1)) {
                status=0;
                while(status<38 && raw[2+status]) { status++; }
                if(!status) { ok=FALSE; break; }
                is_dir=(raw[0]&0x10)!=0; needed+=status+is_dir+1; count++;
              }
            }
            if(ok && buffer && capacity>=needed) {
              if(!I386RedSeaDirectory(volume,directory.block,sector,&size)) ok=FALSE;
              for(index=0;ok && index<size/64;index++) {
                if(!(index&7) && index &&
                    !I386RedSeaSectorRead(volume,directory.block+index/8,sector)) { ok=FALSE; break; }
                raw=sector+(index&7)*64;
                if(!raw[2]) break;
                if(!(raw[1]&1)) {
                  status=0;
                  while(status<38 && raw[2+status]) {
                    buffer[at++]=raw[2+status++];
                  }
                  if(raw[0]&0x10) buffer[at++]='/';
                  buffer[at++]='\n';
                }
              }
              if(ok) buffer[at]=0;
            }
          }
          if(!I386RedSeaEnd(volume)) ok=FALSE;
        }
      }
      I386HeapFree(state->heap,absolute);
    }
  }
  if(state && !I386TaskFilesRelease(state)) ok=FALSE;
  if(ok && entries) *entries=count;
  I386IrqRestore(flags);
  if(ok) return needed;
  return 0;
}

U0 I386TaskDirEntry(U8 *raw,I64 attr,U8 *name,I64 block,I64 size)
{
  I64 i;
  for(i=0;i<64;i++) raw[i]=0;
  raw[0]=attr; raw[1]=attr>>8; i=0;
  while(name[i] && i<37) { raw[2+i]=name[i]; i++; }
  I386RedSeaPutWord(raw+40,block);
  I386RedSeaPutWord(raw+48,size);
}

Bool I386TaskDirMk(U8 *filename,I64 entry_cnt=0)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386RedSea *volume;
  CI386RedSeaEntry parent,created;
  U8 *absolute=0,*buffer=0,*path,*leaf,*cursor;
  I64 drive,status,size;
  Bool result=FALSE,parent_root=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state && task->owner && 0<=entry_cnt<0x100000) {
    absolute=I386FileNameAbs(state->heap,&paths,filename);
    if(absolute) {
      drive=absolute[0]; if('a'<=drive<='z') drive-=32;
      if('A'<=drive<='Z' && absolute[1]==':' && absolute[2]=='/') {
        volume=volumes->letter[drive-'A']; path=absolute+2;
        leaf=path; cursor=path;
        while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
        if(volume && volume->io && *leaf && I386RedSeaBegin(volume)) {
          if(leaf==path+1) { parent.block=volume->root; parent_root=TRUE; }
          else {
            leaf[-1]=0;
            status=I386RedSeaResolve(volume,volume->root,path,&parent);
            leaf[-1]='/';
            if(status!=1) {
              KernelLog("DIR MK resolve error\n"); parent.block=0;
            } else if(!(parent.attr&0x10)) {
              KernelLog("DIR MK parent type error\n"); parent.block=0;
            }
          }
          size=((entry_cnt+3)*64+511)&~511;
          if(parent.block && (buffer=I386HeapAlloc(state->heap,size,TRUE))) {
            status=I386RedSeaFind(volume,parent.block,leaf,&created);
            if(!status) {
              status=I386RedSeaCreate(volume,parent.block,leaf,buffer,size,0,0x810);
              if(status!=1) KernelLog("DIR MK create error\n");
              if(status==1 && parent_root) parent.block=volume->root;
              if(status==1) status=I386RedSeaFind(volume,parent.block,leaf,&created);
              if(status!=1) KernelLog("DIR MK publish error\n");
              if(status==1) {
                I386TaskDirEntry(buffer,0x810,".",created.block,size);
                I386TaskDirEntry(buffer+64,0x810,"..",parent.block,0);
                if(!I386RedSeaSectorWrite(volume,created.block,buffer) ||
                    !I386RedSeaFlush(volume)) {
                  KernelLog("DIR MK header error\n"); status=-1;
                }
              }
              result=status==1;
            } else KernelLog("DIR MK exists/error\n");
          }
          if(!I386RedSeaEnd(volume)) {
            KernelLog("DIR MK end error\n"); result=FALSE;
          }
        }
      }
      I386HeapFree(state->heap,absolute);
    }
    if(buffer) I386HeapFree(state->heap,buffer);
  }
  if(state && !I386TaskFilesRelease(state)) {
    KernelLog("DIR MK release error\n"); result=FALSE;
  }
  I386IrqRestore(flags); return result;
}
