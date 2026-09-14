#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
public U8 *I386TaskAlloc(I64 size,Bool zero=FALSE)
{//Try-allocation in the current task's optional private arena.
  U32 flags=I386IrqSave;
  U8 *result=I386HeapAlloc(I386TaskSelf->memory,size,zero);
  I386IrqRestore(flags);
  return result;
}
public Bool I386TaskFree(U8 *ptr)
{
  U32 flags=I386IrqSave;
  Bool result=I386HeapFree(I386TaskSelf->memory,ptr);
  I386IrqRestore(flags);
  return result;
}
