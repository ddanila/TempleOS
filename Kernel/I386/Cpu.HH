#ifndef I386_CPU_INCLUDED
#define I386_CPU_INCLUDED
//Standalone declarations; IDs match CompilerA.HH. Full kernel uses KernelB.HH.
public _intern 0x71 U8 *GetRBP();
public _intern 0x6C I64 GetRFlags();
public _intern 0x6E U0 SetRFlags(I64 flags);
public extern U32 I386IrqSave();
public extern U0 I386IrqRestore(U32 flags);
#endif
