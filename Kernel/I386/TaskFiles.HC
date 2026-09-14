#include "/Kernel/I386/TaskFiles.HH"
#include "/Kernel/I386/Cpu.HH"
#define I386_TASK_FILES_MAGIC 0x46535431
Bool I386TaskFilesAccess(CI386Task *task)
{
  if(!task) return FALSE;
  if(!task->owner) return TRUE;
  return task->finished || task->owner->current==task || task->owner->current==task->owner->root;
}
CI386TaskFiles *I386TaskFilesValid(CI386Task *task)
{
  CI386TaskFiles *state;
  U8 *directory;
  if(!task || !(state=task->file_state) || state->signature!=I386_TASK_FILES_MAGIC ||
      state->task!=task || !state->environment || !state->volumes ||
      state->bytes<sizeof(CI386TaskFiles)+2 || I386HeapSize(state->heap,state)!=state->bytes ||
      task->file_clone!=&I386TaskFilesClone || task->file_destroy!=&I386TaskFilesDestroy) return 0;
  directory=(state+1)(U8 *);
  if(*directory!='/' || directory[state->bytes-sizeof(CI386TaskFiles)-1]) return 0;
  return state;
}
CI386TaskFiles *I386TaskFilesNew(CI386Task *task,CI386Heap *heap,CFilePathContext *environment,
  CI386FileVolumes *volumes,U8 *directory,U8 drive)
{
  CI386TaskFiles *state;
  U8 *copy;
  I64 length=0,i;
  if(!task || !heap || !environment || !volumes || !directory || *directory!='/' ||
      drive<'A' || drive>'Z' || !environment->home_dir || !environment->white_space) return 0;
  while(directory[length]) {
    if(length>=0xFFFFFFFF-sizeof(CI386TaskFiles)-1) return 0;
    length++;
  }
  state=I386HeapAlloc(heap,sizeof(CI386TaskFiles)+length+1,TRUE);
  if(!state) return 0;
  state->heap=heap; state->task=task; state->environment=environment; state->volumes=volumes;
  state->signature=I386_TASK_FILES_MAGIC; state->bytes=sizeof(CI386TaskFiles)+length+1;
  state->drive=drive;
  copy=(state+1)(U8 *); for(i=0;i<=length;i++) copy[i]=directory[i];
  return state;
}
Bool I386TaskFilesInit(CI386Task *task,CI386Heap *heap,CFilePathContext *environment,CI386FileVolumes *volumes)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state;
  Bool result=FALSE;
  if(!I386TaskFilesAccess(task) || task->finished || task->finishing || task->file_state ||
      task->file_clone || task->file_destroy || !environment) goto files_init_done;
  state=I386TaskFilesNew(task,heap,environment,volumes,environment->cur_dir,environment->cur_drv);
  if(!state) goto files_init_done;
  task->file_state=state; task->file_clone=&I386TaskFilesClone; task->file_destroy=&I386TaskFilesDestroy;
  result=TRUE;
files_init_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskFilesClone(CI386Task *source,CI386Task *target,CI386Heap *heap)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state,*copy;
  Bool result=FALSE;
  state=I386TaskFilesValid(source);
  if(!state || !target || target->owner || target->file_state || target->file_clone || target->file_destroy) goto files_clone_done;
  copy=I386TaskFilesNew(target,heap,state->environment,state->volumes,(state+1)(U8 *),state->drive);
  if(!copy) goto files_clone_done;
  target->file_state=copy; target->file_clone=&I386TaskFilesClone; target->file_destroy=&I386TaskFilesDestroy;
  result=TRUE;
files_clone_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskFilesSet(CI386Task *task,U8 *directory,U8 drive)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state,*copy;
  Bool result=FALSE;
  state=I386TaskFilesValid(task);
  if(!state || !I386TaskFilesAccess(task) || task->finished || task->finishing || state->busy) goto files_set_done;
  copy=I386TaskFilesNew(task,state->heap,state->environment,state->volumes,directory,drive);
  if(!copy) goto files_set_done;
  if(!I386HeapFree(state->heap,state)) { I386HeapFree(copy->heap,copy); goto files_set_done; }
  task->file_state=copy; result=TRUE;
files_set_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskFilesDestroy(CI386Task *task)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state;
  Bool result=FALSE;
  state=I386TaskFilesValid(task);
  if(!state || !I386TaskFilesAccess(task) || state->busy) goto files_destroy_done;
  if(!I386HeapFree(state->heap,state)) goto files_destroy_done;
  task->file_state=0; task->file_clone=0; task->file_destroy=0; result=TRUE;
files_destroy_done:
  I386IrqRestore(flags); return result;
}
CI386TaskFiles *I386TaskFilesBorrow(CI386Task *task,CFilePathContext *paths,CI386FileVolumes **volumes)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state=I386TaskFilesValid(task),*result=0;
  if(!state || !paths || !volumes || !I386TaskFilesAccess(task) || state->busy==0xFFFFFFFF || task->lifetime_refs==0xFFFFFFFF ||
      !state->environment->home_dir || !state->environment->white_space) goto files_borrow_done;
  state->busy++; task->lifetime_refs++;
  paths->cur_dir=(state+1)(U8 *); paths->cur_drv=state->drive;
  paths->home_dir=state->environment->home_dir; paths->boot_drv=state->environment->boot_drv;
  paths->white_space=state->environment->white_space; *volumes=state->volumes;
  result=state;
files_borrow_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskFilesRelease(CI386TaskFiles *state)
{
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(state && I386TaskFilesValid(state->task)==state && state->busy && state->task->lifetime_refs) {
    state->busy--; state->task->lifetime_refs--; result=TRUE;
  }
  I386IrqRestore(flags); return result;
}
