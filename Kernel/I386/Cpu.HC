#include "/Kernel/I386/Cpu.HH"
public U32 I386IrqSave()
{//Single CPU: disable maskable interrupts and return the previous flags.
  U32 flags=GetRFlags;
  SetRFlags(flags&~0x200);
  return flags;
}
public U0 I386IrqRestore(U32 flags)
{//Restore only IF; nested critical sections restore in reverse order.
  SetRFlags((GetRFlags&~0x200)|(flags&0x200));
}
