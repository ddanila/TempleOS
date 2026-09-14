#include "/Kernel/I386/FilePaths.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/BlkDev/FilePaths.HC"
U8 *I386PathNew(CI386Heap *heap,CFilePathContext *context,U8 *name,Bool file)
{
  U8 *work,*result;
  I64 length,capacity,workspace;
  U32 flags;
  if(!heap || !context || !name || !context->white_space || !context->home_dir ||
      !*context->home_dir || context->home_dir[1]!=':' || context->home_dir[2]!='/') return 0;
  length=FileNameLength(name);
  capacity=FilePathCapacity(name,context);
  workspace=length+2;
  if(file) workspace*=2;
  if(capacity>0xFFFFFFFF-24 || workspace>0xFFFFFFFF-24) return 0;
  flags=I386IrqSave;
  work=I386HeapAlloc(heap,workspace,FALSE);
  result=0;
  if(work) {
    result=I386HeapAlloc(heap,capacity,FALSE);
    if(!result) I386HeapFree(heap,work);
  }
  I386IrqRestore(flags);
  if(!result) return 0;
  FilePathCopy(work,name);
  if(file) FilePathFileWrite(result,work,work+length+2,context);
  else FilePathDirWrite(result,work,context);
  flags=I386IrqSave;
  I386HeapFree(heap,work);
  I386IrqRestore(flags);
  return result;
}
U8 *I386DirNameAbs(CI386Heap *heap,CFilePathContext *context,U8 *name)
{
  return I386PathNew(heap,context,name,FALSE);
}
U8 *I386FileNameAbs(CI386Heap *heap,CFilePathContext *context,U8 *name)
{
  return I386PathNew(heap,context,name,TRUE);
}
