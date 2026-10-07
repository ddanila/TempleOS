#include "/Kernel/I386/TaskFileRead.HH"
#include "/Kernel/I386/Cpu.HH"
U8 *(*task_public_read)(CI386Heap *heap,U8 *filename,I64 *size,I64 *attr)=0;
U0 I386TaskFilePublicReader(U8 *callback)
{ task_public_read=callback; }
U8 *I386TaskFileReadMode(CI386Heap *heap,U8 *filename,I64 *size,I64 *attr,U8 **name,Bool raw,Bool stored=FALSE)
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
      task!=task->owner->root,raw,stored);
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
U8 *I386TaskFileRead(CI386Heap *heap,U8 *filename,I64 *size=0,I64 *attr=0,U8 **name=0)
{
  U8 *result,*absolute=0;U32 flags;
  if(!task_public_read)return I386TaskFileReadMode(heap,filename,size,attr,name,FALSE);
  flags=I386IrqSave;
  if(name)absolute=I386TaskFileNameAbs(heap,filename,0);
  if(name && !absolute) {I386IrqRestore(flags);return 0;}
  try {result=task_public_read(heap,filename,size,attr);}
  catch {
    if(absolute)I386HeapFree(heap,absolute);
    I386IrqRestore(flags);I386TaskSelf->catch_except=FALSE;
  }
  if(result) {if(name)*name=absolute;}
  else if(absolute)I386HeapFree(heap,absolute);
  I386IrqRestore(flags);return result;
}
U8 *I386TaskFileReadRaw(CI386Heap *heap,U8 *filename,I64 *size=0,I64 *attr=0,U8 **name=0)
{
  return I386TaskFileReadMode(heap,filename,size,attr,name,TRUE);
}
Bool I386LexTaskFileInclude(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *filename)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *state;
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  Bool result=FALSE;
  U8 *extended=0,*name=0,*source=0;
  state=I386TaskFilesBorrow(task,&paths,&volumes);
  if(state) {
    if(task->owner && task_public_read) {
      if(cc && cc->lex_include_stk && !(cc->flags&CCF_PMT) && !(cc->opts&OPTF_ECHO)) {
        extended=I386ExtDft(heap,filename,"HC.Z");
        if(extended)name=I386FileNameAbs(heap,&paths,extended);
        if(name) {
          try {source=task_public_read(heap,name,0,0);}
          catch {
            I386HeapFree(heap,name);
            if(extended)I386HeapFree(heap,extended);
            I386TaskFilesRelease(state);I386IrqRestore(flags);I386TaskSelf->catch_except=FALSE;
          }
        }
        if(source) {
          result=I386LexIncludeTake(heap,cc,name,source,FALSE);
          if(!result)I386HeapFree(heap,source);
        }
        if(name)I386HeapFree(heap,name);
        if(extended)I386HeapFree(heap,extended);
      }
    } else if(task->owner)result=I386LexIncludeFile(heap,cc,&paths,volumes,filename,task!=task->owner->root);
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
    if(extension)extended=I386ExtDft(heap,name,extension);
    else absolute=I386FileNameAbs(heap,&paths,name);
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

U8 *I386TaskFileReadStored(CI386Heap *heap,U8 *filename,I64 *size=0,I64 *attr=0,U8 **name=0)
{ return I386TaskFileReadMode(heap,filename,size,attr,name,FALSE,TRUE); }
