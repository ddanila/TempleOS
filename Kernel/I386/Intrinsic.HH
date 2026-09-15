#ifndef I386_INTRINSICS_INCLUDED
#define I386_INTRINSICS_INCLUDED
//Canonical declarations for intrinsics implemented by the native i386 backend.
//Opcode values and signatures match CompilerA.HH and the original KernelB.HH.
public _intern 0x77 Bool Bt( U8 *bit_field,I64 bit);
public _intern 0x7A Bool Btc( U8 *bit_field,I64 bit);
public _intern 0x79 Bool Btr( U8 *bit_field,I64 bit);
public _intern 0x78 Bool Bts( U8 *bit_field,I64 bit);
public _intern 0x7D Bool LBtc( U8 *bit_field,I64 bit);
public _intern 0x7C Bool LBtr( U8 *bit_field,I64 bit);
public _intern 0x7B Bool LBts( U8 *bit_field,I64 bit);
public _intern 0x1E I64 ToUpper(U8 ch);
public _intern 0x67 U16 InU16(I64 port);
public _intern 0x68 U32 InU32(I64 port);
public _intern 0x66 U8 InU8(I64 port);
public _intern 0x6A U0 OutU16(I64 port, I64 val);
public _intern 0x6B U0 OutU32(I64 port, I64 val);
public _intern 0x69 U0 OutU8(I64 port, I64 val);
public _intern 0xB3 F64 Abs(F64 d);
public _intern 0xA9 I64 AbsI64(I64 i);
public _intern 0xAD I64 MaxI64(I64 n1,I64 n2);
public _intern 0xAE U64 MaxU64(U64 n1,U64 n2);
public _intern 0xAB I64 MinI64(I64 n1,I64 n2);
public _intern 0xAC U64 MinU64(U64 n1,U64 n2);
public _intern 0xAF U64 ModU64(U64 *q,U64 d);
public _intern 0xAA I64 SignI64(I64 i);
public _intern 0xB2 F64 Sqr(F64 d);
public _intern 0xB0 I64 SqrI64(I64 i);
public _intern 0xB1 U64 SqrU64(U64 i);
public _intern 0xB4 F64 Sqrt(F64 d);
public _intern 0x1D Bool ToBool(I64 i);
public _intern 0x1C F64 ToF64(I64 i);
public _intern 0x1B I64 ToI64(F64 d);
public _intern 0x71 U8 *GetRBP();
public _intern 0x73 U8 *GetRSP();
public _intern 0x6C I64 GetRFlags();
public _intern 0x6E U0 SetRFlags(I64 d);
#endif
