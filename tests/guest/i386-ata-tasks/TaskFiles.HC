#include "/Kernel/I386/TaskFiles.HH"
#include "/Kernel/I386/TaskModuleStage.HH"
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
  I64 i,n,used=heap.used,allocations=heap.allocations;
  if(!I386RedSeaBegin(&volumes[0]))return 41;
  //Reserve directory/data sectors; the fixture previously needed no allocator.
  for(i=0;i<512;i++)bitmap[i]=255;
  bitmap[0]=0x6F;bitmap[1]=0x98;
  if(!I386RedSeaSectorWrite(&volumes[0],2049,bitmap) ||
      !I386RedSeaFlush(&volumes[0]) || !I386RedSeaEnd(&volumes[0]))return 42;
  for(i=0;i<1025;i++)source[i]=(i*13+7)&255;
  unit=I386TaskModuleStageNew("C:/Check.t32m",0);
  if(!unit || !state->stage || state->busy || root.io_locks ||
      I386TaskFilesSet(&root,"/",'C') || I386TaskModuleStageNew("C:/Two",65))return 43;
  if(unit->owned || unit->phase || (*unit->emit)(unit,0,source,17) ||
      !(*unit->reserve)(unit,1025) || (*unit->reserve)(unit,1025))return 55;
  for(i=0;i<1025;i+=17) {
    n=1025-i;if(n>17)n=17;
    if((*unit->emit)(unit,i,source+i,n)!=n)return 44;
  }
  if(!(*unit->seal)(unit) || (*unit->readback)(unit,output,1025) ||
      !(*unit->unwound)(unit,TRUE) || !(*unit->readback)(unit,output,1025))return 45;
  for(i=0;i<1025;i++)if(source[i]!=output[i])return 46;
  I386RedSeaTaskFailArm(3,1);
  if(I386TaskFilesDestroy(&root) || !state->stage || !unit->owned ||
      volumes[0].signature || root.io_locks || channel.owner)return 47;
  I386RedSeaTaskFailArm(0,0);
  if(!(*state->stage->cleanup)(state->stage->context) || state->stage ||
      volumes[0].signature || heap.used!=used || heap.allocations!=allocations)return 48;
  if(!I386RedSeaMount(&volumes[0],&disks[0],2048) ||
      !I386RedSeaTaskBind(&volumes[0],&volume_io))return 49;
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
