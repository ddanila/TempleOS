#ifndef I386_TASK_FILES_INCLUDED
#define I386_TASK_FILES_INCLUDED
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/FileContext.HH"
class CI386TaskFiles {
  CI386Heap *heap;
  CI386Task *task;
  CFilePathContext *environment;
  CI386FileVolumes *volumes;
  U32 signature,bytes,busy;
  U8 drive;
};
//Owned directory bytes follow the record. Environment home/boot/bitmap and the
//volume table are borrowed and must stay live. Init/Set are internal state commits,
//not Cd: callers supply an already established rooted directory and drive letter.
public extern Bool I386TaskFilesInit(CI386Task *task,CI386Heap *heap,CFilePathContext *environment,CI386FileVolumes *volumes);
public extern Bool I386TaskFilesClone(CI386Task *source,CI386Task *target,CI386Heap *heap);
public extern Bool I386TaskFilesSet(CI386Task *task,U8 *directory,U8 drive);
public extern Bool I386TaskFilesDestroy(CI386Task *task);
//Current/root/finished-task inspection. Balance each successful borrow; a borrow
//prevents state replacement and reaping. Output snapshots are caller-owned.
public extern CI386TaskFiles *I386TaskFilesBorrow(CI386Task *task,CFilePathContext *paths,CI386FileVolumes **volumes);
public extern Bool I386TaskFilesRelease(CI386TaskFiles *state);
#endif
