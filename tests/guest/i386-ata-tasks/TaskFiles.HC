#include "/Kernel/I386/TaskFiles.HH"
CI386FileVolumes task_volumes;
CFilePathContext task_environment;
U32 task_white_space[8],task_files_done,task_files_busy;
extern U0 DirectoryReader(I64 id);
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
