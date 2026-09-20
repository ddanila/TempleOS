#include "/Kernel/I386/TaskFileRead.HH"
#include "/Kernel/I386/Cpu.HH"
U8 *I386TaskFileRead(CI386Heap *heap,U8 *filename,I64 *size=0,I64 *attr=0,U8 **name=0)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  U8 *result=0,*absolute=0;
  I64 bytes,attributes;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state) {
    if(task->owner) result=I386FileReadAt(heap,&paths,volumes,filename,&bytes,&attributes,&absolute,
      task!=task->owner->root);
    if(!I386TaskFilesRelease(state)) {
      if(result) I386HeapFree(heap,result);
      if(absolute) I386HeapFree(heap,absolute);
      result=0;
    }
    if(result) {
      if(size) *size=bytes;
      if(attr) *attr=attributes;
      if(name) *name=absolute; else I386HeapFree(heap,absolute);
    }
  }
  I386IrqRestore(flags); return result;
}
Bool I386LexTaskFileInclude(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *filename)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  Bool result=FALSE;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state) {
    if(task->owner) result=I386LexIncludeFile(heap,cc,&paths,volumes,filename,task!=task->owner->root);
    if(!I386TaskFilesRelease(state)) result=FALSE;
  }
  I386IrqRestore(flags); return result;
}

U8 *I386TaskFileNameAbs(CI386Heap *heap,U8 *name,U8 *extension)
{
  U32 flags=I386IrqSave;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  U8 *extended=0,*absolute=0;
  state=I386TaskFilesBorrow(I386TaskSelf,&paths,&volumes);
  if(state) {
    extended=I386ExtDft(heap,name,extension);
    if(extended) {
      absolute=I386FileNameAbs(heap,&paths,extended);
      I386HeapFree(heap,extended);
    }
    if(!I386TaskFilesRelease(state)) {
      if(absolute) I386HeapFree(heap,absolute);
      absolute=0;
    }
  }
  I386IrqRestore(flags); return absolute;
}
