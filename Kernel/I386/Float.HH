#ifndef I386_FLOAT_INCLUDED
#define I386_FLOAT_INCLUDED
//Standalone intrinsic declarations; IDs match Compiler/CompilerA.HH.
//Numeric conversion is distinct from a HolyC bitwise typecast.
public _intern 0x1C F64 ToF64(I64 value);
public _intern 0x1B I64 ToI64(F64 value);
#endif
