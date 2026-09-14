#ifndef I386_MATH_INCLUDED
#define I386_MATH_INCLUDED
//Standalone integer intrinsic declarations, matching KernelB.HH.
public _intern 0xA9 I64 AbsI64(I64 value);
public _intern 0xAA I64 SignI64(I64 value);
public _intern 0xAB I64 MinI64(I64 a,I64 b);
public _intern 0xAC U64 MinU64(U64 a,U64 b);
public _intern 0xAD I64 MaxI64(I64 a,I64 b);
public _intern 0xAE U64 MaxU64(U64 a,U64 b);
public _intern 0xB0 I64 SqrI64(I64 value);
public _intern 0xB1 U64 SqrU64(U64 value);
#endif
