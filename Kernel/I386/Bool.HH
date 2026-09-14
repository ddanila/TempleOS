#ifndef I386_BOOL_INCLUDED
#define I386_BOOL_INCLUDED
//Standalone declaration; matches KernelB.HH and Compiler/CompilerA.HH.
//The I64 argument is normalized to zero or one, using all 64 bits.
public _intern 0x1D Bool ToBool(I64 value);
#endif
