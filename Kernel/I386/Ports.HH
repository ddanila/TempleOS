#ifndef I386_PORTS_INCLUDED
#define I386_PORTS_INCLUDED
//Standalone target declarations. Intrinsic IDs match Compiler/CompilerA.HH.
//Include Kernel/Types.HH first; the full kernel uses KernelB.HH declarations.
public _intern 0x66 U8 InU8(I64 port);
public _intern 0x67 U16 InU16(I64 port);
public _intern 0x68 U32 InU32(I64 port);
public _intern 0x69 U0 OutU8(I64 port,I64 val);
public _intern 0x6A U0 OutU16(I64 port,I64 val);
public _intern 0x6B U0 OutU32(I64 port,I64 val);
#endif
