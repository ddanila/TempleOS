#ifndef I386_TASK_FILE_READ_INCLUDED
#define I386_TASK_FILE_READ_INCLUDED
#include "/Kernel/I386/TaskFiles.HH"
#include "/Compiler/I386/LexFileRead.HH"
//Current-task bootstrap services, preserving IF. Borrowed configuration stays live
//and stable across scheduling; worker volumes must have a task-owned session.
public extern U8 *I386TaskFileRead(CI386Heap *heap,U8 *filename,I64 *size=0,I64 *attr=0,U8 **name=0);
public extern U8 *I386TaskFileNameAbs(CI386Heap *heap,U8 *name,U8 *extension);
public extern Bool I386LexTaskFileInclude(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *filename);
#endif
