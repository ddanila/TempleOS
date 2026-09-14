#include "/Kernel/I386/FileNames.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/BlkDev/FileNames.HC"
U8 *I386ExtDft(CI386Heap *heap,U8 *name,U8 *extension)
{
  U8 *result;
  I64 size;
  U32 flags;
  if(!heap || !name || !extension) return 0;
  size=FileNameLength(name)+1;
  if(!FileExtDot(name)) size+=FileNameLength(extension)+1;
  flags=I386IrqSave;
  result=I386HeapAlloc(heap,size,FALSE);
  I386IrqRestore(flags);
  if(result) FileNameWriteDefault(result,name,extension);
  return result;
}
U8 *I386ToggleZorNotZ(CI386Heap *heap,U8 *name)
{
  U8 *result;
  I64 size;
  U32 flags;
  if(!heap || !name) return 0;
  size=FileNameLength(name)+3;
  if(IsDotZ(name)) size-=4;
  flags=I386IrqSave;
  result=I386HeapAlloc(heap,size,FALSE);
  I386IrqRestore(flags);
  if(result) FileNameWriteToggle(result,name);
  return result;
}
