#include "/Kernel/I386/TaskFiles.HH"
#include "/Kernel/I386/TaskModuleStage.HH"
#include "/Kernel/I386/RedSeaPublication.HC"
CI386FileVolumes task_volumes;
CFilePathContext task_environment;
U32 task_white_space[8],task_files_done,task_files_busy;
extern U0 DirectoryReader(I64 id);
extern I64 I386ModuleStageWrite(U8 *context,U32 offset,U8 *buffer,U32 bytes);
extern Bool I386ModuleStageSeal(CI386ModuleStage *stage);
extern Bool I386ModuleStageUnwound(CI386ModuleStage *stage,Bool clean);
extern Bool I386ModuleStageRead(CI386ModuleStage *stage,U8 *buffer,I64 bytes);
U0 StageWorker(U8 *unused)
{
  CI386ModuleStage *unit;U8 bytes[65];I64 i;
  no_warn unused;
  for(i=0;i<65;i++)bytes[i]=i+1;
  unit=I386TaskModuleStageNew("C:/Exit.t32m",65);
  if(!unit || (*unit->emit)(unit,0,bytes,17)!=17)errors++;
  //Task exit deliberately leaves the unsealed reservation for the reaper.
}
U32 stage_cancel_started,stage_cancel_done;
Bool publication_fail_after_write;
Bool PublicationWriteFault(U8 *context,CI386Ata *disk,I64 block,U8 *buffer)
{
  Bool result=I386RedSeaTaskWrite(context,disk,block,buffer);
  if(result && block==2050 && publication_fail_after_write) {
    publication_fail_after_write=FALSE;return FALSE;
  }
  return result;
}
I64 PublicationTest(U8 *source,U8 *bitmap)
{
  CI386RedSeaPublication publication;
  CI386ModuleStage *unit;CI386TaskModuleStage *stage;
  CI386TaskFiles *owner=root.file_state;
  CI386RedSea *view;
  U8 original[512],entry[64],reserved[512],current[512];
  U8 *new_name="New.BIN";
  I64 mode,i,index,fresh,used=heap.used,allocations=heap.allocations;
  U32 slot;
  Bool result;
  for(mode=0;mode<7;mode++) {
    SVSet(&publication,0,sizeof(CI386RedSeaPublication));
    unit=I386TaskModuleStageNew("C:/Data.BIN",1025);stage=unit;
    if(!unit || (*unit->emit)(unit,0,source,1025)!=1025 ||
        !(*unit->seal)(unit) || !(*unit->unwound)(unit,TRUE))return 68;
    fresh=stage->block;
    if(!I386RedSeaBegin(&volumes[0]) ||
        !I386RedSeaSectorRead(&volumes[0],2050,original))return 69;
    for(i=0;i<64;i++)entry[i]=original[128+i];
    slot=2;
    if(mode==6) {
      slot=5;for(i=0;i<38;i++)entry[2+i]=0;
      for(i=0;i<7;i++)entry[2+i]=new_name[i];
    }
    I386RedSeaPutWord(entry+40,fresh);I386RedSeaPutWord(entry+48,1025);
    if(!I386RedSeaPublicationInit(&publication,&volumes[0],2050,slot,entry,&stage->block))return 70;
    if(mode==1)I386RedSeaTaskFailArm(2,1);
    if(mode==2){publication_fail_after_write=TRUE;volume_io.write=&PublicationWriteFault;}
    if(mode==3)I386RedSeaTaskFailArm(3,2);
    if(mode==4)I386RedSeaTaskFailArm(3,3);
    if(mode==5)I386RedSeaTaskFailArm(3,1);
    result=I386RedSeaPublicationCommit(&publication);
    volume_io.write=&I386RedSeaTaskWrite;I386RedSeaTaskFailArm(0,0);
    if(!mode || mode==6) {if(!result)return 71;}
    else {
      if(result || volumes[0].signature)return 72;
      if(mode==4) {
        if(stage->block || publication.transaction.phase!=I386_PUBLISH_COMMITTED)return 73;
      } else if(stage->block!=fresh)return 74;
      if(mode==5) {
        if(!I386ModulePublishAbortable(&publication.transaction))return 75;
      } else {
        if(mode!=4 && I386ModulePublishAbortable(&publication.transaction))return 76;
        result=I386RedSeaPublicationRecover(&publication);
        if(mode==1) {
          if(result || !I386ModulePublishAbortable(&publication.transaction) || stage->block!=fresh)return 77;
        } else if(!result || stage->block || publication.transaction.phase!=I386_PUBLISH_DONE)return 78;
      }
    }
    view=publication.volume;
    if(mode!=1 && mode!=5) {
      if(!I386RedSeaSectorRead(view,2050,current) ||
          !I386RedSeaPublicationEqual(current+slot*64,entry))return 79;
      for(i=0;i<512;i++)if((i<slot*64 || i>=slot*64+64) && current[i]!=original[i])return 85;
      if(!I386RedSeaSectorRead(view,2049,current))return 79;
      //Restore fixture safely: reserve old and fresh before restoring its name.
      for(i=0;i<512;i++)reserved[i]=bitmap[i];
      for(i=0;i<3;i++) {index=fresh+i-(view->first-1);reserved[index/8]|=1<<(index&7);}
      for(i=0;i<512;i++) {
        index=reserved[i];if(i==1 && mode!=6)index&=~0x18;
        if(current[i]!=index)return 84;
      }
      if(!I386RedSeaSectorWrite(view,2049,reserved) || !I386RedSeaFlush(view) ||
          !I386RedSeaSectorWrite(view,2050,original) || !I386RedSeaFlush(view) ||
          !I386RedSeaSectorWrite(view,2049,bitmap) || !I386RedSeaFlush(view))return 80;
    }
    if(!I386RedSeaEnd(&volumes[0]) ||
        !(*owner->stage->cleanup)(owner->stage->context) ||
        heap.used!=used || heap.allocations!=allocations)return 81;
    if(!volumes[0].signature && (!I386RedSeaMount(&volumes[0],&disks[0],2048) ||
        !I386RedSeaTaskBind(&volumes[0],&volume_io)))return 82;
    if(root.io_locks || channel.owner || channel.head || channel.tail)return 83;
  }
  return 0;
}
I64 stage_read_fail_after,stage_read_count;
Bool StageReadFault(U8 *context,CI386Ata *disk,I64 block,U8 *buffer)
{
  if(++stage_read_count==stage_read_fail_after)return FALSE;
  return I386RedSeaTaskRead(context,disk,block,buffer);
}
U0 StageCancelWorker(U8 *unused)
{
  CI386ModuleStage *unit;
  no_warn unused;
  unit=I386TaskModuleStageNew("C:/Cancelled.t32m",0);
  if(!unit){errors++;return;}
  stage_cancel_started=1;
  if((*unit->reserve)(unit,65) || unit->phase!=I386_STAGE_FAILED ||
      !unit->owned || I386TaskSelf->io_locks)errors++;
  stage_cancel_done=1;
}
I64 StageTest()
{
  CI386TaskFiles *state=root.file_state;
  CI386ModuleStage *unit;
  CI386OwnedTask *worker;
  U8 source[1025],output[1025],bitmap[512],after[512];
  CI386ModuleHeader *header=source;
  I64 i,n,used=heap.used,allocations=heap.allocations;
  if(!SVNativeRun)return 67;
  if(!I386RedSeaBegin(&volumes[0]))return 41;
  //Reserve directory/data sectors; the fixture previously needed no allocator.
  for(i=0;i<512;i++)bitmap[i]=255;
  bitmap[0]=0x6F;bitmap[1]=0x98;
  if(!I386RedSeaSectorWrite(&volumes[0],2049,bitmap) ||
      !I386RedSeaFlush(&volumes[0]) || !I386RedSeaEnd(&volumes[0]))return 42;
  for(i=0;i<1025;i++)source[i]=(i*13+7)&255;
  header->magic=I386_MODULE_MAGIC;header->version=2;header->cpu=3;header->pointer_size=4;
  header->abi=1;header->total_size=1025;header->code_size=984;
  header->record_count=0;header->records_offset=header->strings_offset=1016;
  unit=I386TaskModuleStageNew("C:/Check.t32m",0);
  if(!unit || !state->stage || state->busy || root.io_locks ||
      I386TaskFilesSet(&root,"/",'C') || I386TaskModuleStageNew("C:/Two",65))return 43;
  if(unit->owned || unit->phase || (*unit->emit)(unit,0,source,17) ||
      !(*unit->reserve)(unit,1025) || (*unit->reserve)(unit,1025))return 55;
  for(i=0;i<1025;i+=17) {
    n=1025-i;if(n>17)n=17;
    if((*unit->emit)(unit,i,source+i,n)!=n)return 44;
  }
  if(I386TaskModuleStageReadRange(unit,0,output,1) ||
      !(*unit->seal)(unit) || (*unit->readback)(unit,output,1025) ||
      I386TaskModuleStageReadRange(unit,0,output,1) ||
      !(*unit->unwound)(unit,TRUE))return 45;
  if(I386TaskModuleStageReadRange(unit,1025,output,1) ||
      I386TaskModuleStageReadRange(unit,1024,output,2) ||
      I386TaskModuleStageReadRange(unit,0,output,4097) ||
      I386TaskModuleStageReadRange(unit,0,output,0) ||
      I386TaskModuleStageReadRange(unit,0,0,1) ||
      I386TaskModuleStageReadRange(unit,0xFFFFFFFF,output,2) ||
      unit->phase!=I386_STAGE_READY)return 60;
  if(I386TaskModuleStageReadRange(unit,507,output,17)!=17)return 61;
  for(i=0;i<17;i++)if(output[i]!=source[507+i])return 62;
  if(I386TaskModuleStageReadRange(unit,1024,output,1)!=1 ||
      output[0]!=source[1024] || unit->phase!=I386_STAGE_READY ||
      !unit->owned || root.io_locks || channel.owner ||
      !I386ModuleStageValid(unit,output,9,&I386ModuleValidParts) ||
      !(*unit->readback)(unit,output,1025))return 63;
  for(i=0;i<1025;i++)if(source[i]!=output[i])return 46;
  I386RedSeaTaskFailArm(3,1);
  if(I386TaskFilesDestroy(&root) || !state->stage || !unit->owned ||
      volumes[0].signature || root.io_locks || channel.owner)return 47;
  I386RedSeaTaskFailArm(0,0);
  if(!(*state->stage->cleanup)(state->stage->context) || state->stage ||
      volumes[0].signature || heap.used!=used || heap.allocations!=allocations)return 48;
  if(!I386RedSeaMount(&volumes[0],&disks[0],2048) ||
      !I386RedSeaTaskBind(&volumes[0],&volume_io))return 49;
  for(n=1;n<=2;n++) {
    unit=I386TaskModuleStageNew("C:/ReadFault.t32m",1025);
    if(!unit || (*unit->emit)(unit,0,source,1025)!=1025 ||
        !(*unit->seal)(unit) || !(*unit->unwound)(unit,TRUE))return 64;
    stage_read_count=0;stage_read_fail_after=n;volume_io.read=&StageReadFault;
    if((*unit->read_range)(unit,507,output,17) ||
        unit->phase!=I386_STAGE_FAILED || !unit->owned ||
        (*unit->read_range)(unit,0,output,1) || stage_read_count!=n ||
        root.io_locks || channel.owner)return 65;
    volume_io.read=&I386RedSeaTaskRead;
    if(!(*state->stage->cleanup)(state->stage->context) || state->stage ||
        heap.used!=used || heap.allocations!=allocations)return 66;
  }
  worker=I386TaskSpawn(&scheduler,&heap,8192,&StageWorker,0,0x18,0x20,512);
  if(!worker)return 50;
  for(i=0;i<100 && !worker->task.finished;i++)I386SchedYield(&scheduler);
  if(!worker->task.finished || !worker->task.file_state ||
      !((worker->task.file_state(CI386TaskFiles *))->stage) ||
      !I386TaskDestroy(worker) || heap.used!=used || heap.allocations!=allocations)return 51;
  if(!I386RedSeaBegin(&volumes[0]))return 56;
  worker=I386TaskSpawn(&scheduler,&heap,8192,&StageCancelWorker,0,0x18,0x20,512);
  if(!worker)return 57;
  for(i=0;i<100 && !worker->task.wait;i++)I386SchedYield(&scheduler);
  if(!stage_cancel_started || !worker->task.wait || !worker->task.blocked ||
      !channel.head || I386TaskFilesDestroy(&worker->task) ||
      !I386TaskCancelWait(&worker->task))return 58;
  for(i=0;i<100 && !worker->task.finished;i++)I386SchedYield(&scheduler);
  if(!worker->task.finished || !stage_cancel_done || worker->task.wait ||
      channel.head || channel.tail || channel.owner!=&root || root.io_locks!=1 ||
      !I386TaskDestroy(worker) || heap.used!=used || heap.allocations!=allocations ||
      !I386RedSeaEnd(&volumes[0]))return 59;
  if(!I386RedSeaBegin(&volumes[0]) || !I386RedSeaSectorRead(&volumes[0],2049,after) ||
      !I386RedSeaEnd(&volumes[0]))return 52;
  for(i=0;i<512;i++)if(bitmap[i]!=after[i])return 53;
  i=PublicationTest(source,bitmap);if(i)return i;
  if(state->stage || state->busy || root.io_locks || channel.owner || channel.poisoned)return 54;
  return 0;
}
I64 TaskFilesTest()
{
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *selected;
  I64 i,round,used,allocations;
  task_environment.cur_dir="/One"; task_environment.cur_drv='C';
  task_environment.home_dir="C:/"; task_environment.boot_drv='C';
  task_environment.white_space=task_white_space;
  task_volumes.letter['C'-'A']=&volumes[0]; task_volumes.letter['D'-'A']=&volumes[1];
  if(!I386TaskFilesInit(&root,&heap,&task_environment,&task_volumes) ||
      I386TaskFilesInit(&root,&heap,&task_environment,&task_volumes)) return 30;
  used=heap.used; allocations=heap.allocations;
  i=StageTest;if(i)return i;
  if(I386TaskSpawn(&scheduler,&heap,8192,&DirectoryReader,0,0x18,0x20,24) ||
      heap.used!=used || heap.allocations!=allocations || root.next!=&root) return 31;
  if(I386TaskFilesSet(&root,"relative",'C') || I386TaskFilesSet(&root,"/",'c')) return 32;
  state=I386TaskFilesBorrow(&root,&paths,&selected);
  if(!state || selected!=&task_volumes || paths.cur_drv!='C' || paths.cur_dir[1]!='O' ||
      I386TaskFilesDestroy(&root) || I386TaskFilesSet(&root,"/Two",'D')) return 33;
  state->busy=0xFFFFFFFF;
  if(I386TaskFilesBorrow(&root,&paths,&selected)) return 34;
  state->busy=1;
  if(!I386TaskFilesRelease(state) || I386TaskFilesRelease(state)) return 35;
  for(i=0;i<2;i++) {
    workers[i]=I386TaskSpawn(&scheduler,&heap,8192,&DirectoryReader,i,0x18,0x20,512);
    if(!workers[i] || !workers[i]->task.file_state || workers[i]->task.file_state==root.file_state) return 36;
  }
  I386PicMask(0xFFFC);
  for(round=0;round<1000;round++) {
    I386SchedYield(&scheduler);
    for(i=0;i<2;i++) {
      state=workers[i]->task.file_state;
      if(state->busy) {
        task_files_busy++;
        if(I386TaskFilesSet(&workers[i]->task,"/",'D') ||
            I386TaskFilesDestroy(&workers[i]->task)) return 37;
      }
    }
    if(workers[0]->task.finished && workers[1]->task.finished) break;
  }
  I386PicMask(0xFFFF);
  if(errors || task_files_done!=2 || !task_files_busy || channel.owner || channel.head || channel.poisoned) return 38;
  for(i=0;i<2;i++) {
    state=I386TaskFilesBorrow(&workers[i]->task,&paths,&selected);
    if(!state || I386TaskDestroy(workers[i]) || !I386TaskFilesRelease(state) ||
        !I386TaskDestroy(workers[i])) return 39;
  }
  state=I386TaskFilesBorrow(&root,&paths,&selected);
  if(!state || paths.cur_dir[1]!='O' || paths.cur_drv!='C' ||
      !I386TaskFilesRelease(state) || heap.used!=used || heap.allocations!=allocations ||
      !I386TaskFilesDestroy(&root) || heap.used || heap.allocations || !I386HeapValid(&heap)) return 40;
  return 0;
}
U0 DirectoryReader(I64 id)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *selected;
  U8 huge[600],*name,*bytes;
  I64 i,size=-1;
  for(i=0;i<599;i++) huge[i]='a'; huge[0]='/'; huge[599]=0;
  if(I386TaskFilesSet(task,huge,'D')) { errors++; return; }
  if(id && !I386TaskFilesSet(task,"/Two",'D')) { errors++; return; }
  state=I386TaskFilesBorrow(task,&paths,&selected);
  if(!state || paths.cur_drv!='C'+id || paths.cur_dir[1]!="OT"(U8 *)[id]) { errors++; return; }
  name=I386FileNameAbs(&heap,&paths,"Local.BIN");
  if(!name) { errors++; return; }
  bytes=I386RedSeaFileRead(selected->letter[paths.cur_drv-'A'],&heap,volumes[id].root,name+2,&size);
  if(!bytes || size!=512 || bytes[size] || task->io_locks || (GetRFlags&0x200)) { errors++; return; }
  for(i=0;i<size;i++) if(bytes[i]!=0x51+id) errors++;
  if(!I386HeapFree(&heap,bytes) || !I386HeapFree(&heap,name) || !I386TaskFilesRelease(state)) errors++;
  task_files_done++;
}
#include "/Kernel/I386/TaskFiles.HC"
#include "/Kernel/BlkDev/FileNames.HC"
#include "/Kernel/I386/FilePaths.HC"

#include "/Kernel/I386/RedSeaAlloc.HC"
#include "/Kernel/I386/TaskModuleStage.HC"
