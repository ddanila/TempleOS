#include "/Kernel/I386/TaskFiles.HH"
#include "/Kernel/I386/FileVolumes.HC"
#include "/Kernel/I386/Cpu.HH"
#define I386_TASK_FILES_MAGIC 0x46535431
Bool I386TaskFilesAccess(CI386Task *task)
{
  if(!task) return FALSE;
  if(!task->owner) return TRUE;
  return task->finished || task->owner->current==task || task->owner->current==task->owner->root;
}
CI386TaskFiles *I386TaskFilesState(CI386Task *task,Bool require_directory)
{
  CI386TaskFiles *state;
  CI386TaskHeaps *owner;
  U8 *directory;
  I64 bytes,capacity,i;
  if(!task || !(state=task->file_state) || state->signature!=I386_TASK_FILES_MAGIC ||
      state->task!=task || !state->environment || !state->volumes ||
      task->file_clone!=&I386TaskFilesClone || task->file_destroy!=&I386TaskFilesDestroy) return 0;
  bytes=I386HeapSize(state->heap,state);directory=task->cur_dir;
  if(require_directory && (!directory || *directory!='/'))return 0;
  if(owner=state->directory_owner) {
    if(bytes!=sizeof(CI386TaskFiles) || owner!=task->heap_state || owner->task!=task ||
        owner->signature!=I386_TASK_HEAPS_MAGIC || !owner->code_allocate ||
        !owner->code_release || !owner->code_capacity)return 0;
    if(!require_directory)return state;
    capacity=(*owner->code_capacity)(owner,directory);
    for(i=1;i<capacity;i++)if(!directory[i])return state;
    return 0;
  }
  if(bytes<sizeof(CI386TaskFiles)+2)return 0;
  if(!require_directory)return state;
  if(directory!=(state+1)(U8 *) ||
      directory[bytes-sizeof(CI386TaskFiles)-1])return 0;
  return state;
}
CI386TaskFiles *I386TaskFilesValid(CI386Task *task)
{ return I386TaskFilesState(task,TRUE); }
U8 I386TaskFilesLetter(CI386TaskFiles *state)
{//Public field assignment is part of original directory-context restoration.
  CDrv *drive=state->task->cur_dv;
  if(drive && drive->dv_signature==DRV_SIGNATURE_VAL)return drive->drv_let;
  if(!state->directory_owner)return state->drive;
  return 0;
}
CI386TaskFiles *I386TaskFilesNew(CI386Task *task,CI386Heap *heap,CFilePathContext *environment,
  CI386FileVolumes *volumes,U8 *directory,U8 drive,U8 **new_directory)
{
  CI386TaskFiles *state;
  U8 *copy;
  CI386TaskHeaps *owner;
  I64 length=0,i,bytes;
  if(!task || !heap || !environment || !volumes || !directory || *directory!='/' ||
      drive<'A' || drive>'Z' || !environment->home_dir || !environment->white_space) return 0;
  while(directory[length]) {
    if(length>=0xFFFFFFFF-sizeof(CI386TaskFiles)-1) return 0;
    length++;
  }
  owner=task->heap_state;
  if(owner && (owner->task!=task || owner->signature!=I386_TASK_HEAPS_MAGIC ||
      !owner->code_allocate || !owner->code_release || !owner->code_capacity))return 0;
  bytes=sizeof(CI386TaskFiles);if(!owner)bytes+=length+1;
  state=I386HeapAlloc(heap,bytes,TRUE);
  if(!state) return 0;
  state->heap=heap; state->task=task; state->environment=environment; state->volumes=volumes;
  state->signature=I386_TASK_FILES_MAGIC; state->directory_owner=owner;
  state->drive=drive;
  if(owner)copy=(*owner->code_allocate)(owner,length+1);else copy=(state+1)(U8 *);
  if(!copy){I386HeapFree(heap,state);return 0;}
  for(i=0;i<=length;i++)copy[i]=directory[i];
  *new_directory=copy;
  return state;
}
Bool I386TaskFilesFree(CI386TaskFiles *state,U8 *directory)
{
  if(state->directory_owner &&
      !(*state->directory_owner->code_release)(state->directory_owner,directory))return FALSE;
  return I386HeapFree(state->heap,state);
}
Bool I386TaskFilesInit(CI386Task *task,CI386Heap *heap,CFilePathContext *environment,CI386FileVolumes *volumes)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state;
  U8 *directory;
  Bool result=FALSE;
  if(!I386TaskFilesAccess(task) || task->finished || task->finishing || task->file_state ||
      task->file_clone || task->file_destroy || !environment) goto files_init_done;
  state=I386TaskFilesNew(task,heap,environment,volumes,environment->cur_dir,environment->cur_drv,&directory);
  if(!state) goto files_init_done;
  if(!volumes->resident_heap) volumes->resident_heap=heap;
  task->file_state=state; task->file_clone=&I386TaskFilesClone; task->file_destroy=&I386TaskFilesDestroy;
  task->cur_dir=directory;
  task->cur_dv=I386TaskFilesDrive(state->volumes,state->drive);
  result=TRUE;
files_init_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskFilesCloneMode(CI386Task *source,CI386Task *target,CI386Heap *heap,Bool home)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state,*copy;
  U8 *new_directory,*directory,drive;
  CDrv *identity;
  Bool result=FALSE;
  state=I386TaskFilesState(source,!home);
  if(!state || !target || target->owner || target->file_state || target->file_clone || target->file_destroy) goto files_clone_done;
  if(home) {
    directory=state->environment->home_dir;
    if(!directory || directory[0]<'A' || directory[0]>'Z' ||
        directory[1]!=':' || directory[2]!='/')goto files_clone_done;
    drive=directory[0];directory+=2;
    identity=I386TaskFilesDrive(state->volumes,drive);
  } else {
    directory=source->cur_dir;drive=I386TaskFilesLetter(state);identity=source->cur_dv;
  }
  copy=I386TaskFilesNew(target,heap,state->environment,state->volumes,directory,drive,&new_directory);
  if(!copy) goto files_clone_done;
  target->file_state=copy; target->file_clone=&I386TaskFilesClone; target->file_destroy=&I386TaskFilesDestroy;
  target->cur_dir=new_directory;target->cur_dv=identity;
  result=TRUE;
files_clone_done:
  I386IrqRestore(flags); return result;
}
Bool I386TaskFilesClone(CI386Task *source,CI386Task *target,CI386Heap *heap)
{//Private foundation workers retain explicit parent-context inheritance.
  return I386TaskFilesCloneMode(source,target,heap,FALSE);
}
Bool I386TaskFilesPublicClone(CI386Task *source,CI386Task *target,CI386Heap *heap)
{//Original TaskInit selects the configured home independently from its parent.
  return I386TaskFilesCloneMode(source,target,heap,TRUE);
}
Bool I386TaskFilesSet(CI386Task *task,U8 *directory,U8 drive)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state,*copy;
  U8 *new_directory;
  Bool result=FALSE;
  state=I386TaskFilesValid(task);
  if(!state || !I386TaskFilesAccess(task) || task->finished || task->finishing || state->busy || state->stage) goto files_set_done;
  copy=I386TaskFilesNew(task,state->heap,state->environment,state->volumes,directory,drive,&new_directory);
  if(!copy) goto files_set_done;
  if(!I386TaskFilesFree(state,task->cur_dir)) { I386TaskFilesFree(copy,new_directory); goto files_set_done; }
  task->file_state=copy; task->cur_dir=new_directory;
  task->cur_dv=I386TaskFilesDrive(copy->volumes,copy->drive); result=TRUE;
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
  if(state->stage && (!state->stage->cleanup ||
      !(*state->stage->cleanup)(state->stage->context) || state->stage)) goto files_destroy_done;
  if(!I386TaskFilesFree(state,task->cur_dir)) goto files_destroy_done;
  task->file_state=0; task->file_clone=0; task->file_destroy=0;
  task->cur_dir=0; task->cur_dv=0; result=TRUE;
files_destroy_done:
  I386IrqRestore(flags); return result;
}
CI386TaskFiles *I386TaskFilesBorrow(CI386Task *task,CFilePathContext *paths,CI386FileVolumes **volumes)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state=I386TaskFilesValid(task),*result=0;
  if(!state || !paths || !volumes || !I386TaskFilesAccess(task) || state->busy==0xFFFFFFFF || task->lifetime_refs==0xFFFFFFFF ||
      !state->environment->home_dir || !state->environment->white_space) goto files_borrow_done;
  paths->cur_drv=I386TaskFilesLetter(state);if(!paths->cur_drv)goto files_borrow_done;
  state->busy++; task->lifetime_refs++;
  paths->cur_dir=task->cur_dir;
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
