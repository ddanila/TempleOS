#ifndef I386_PUBLIC_MATH_INCLUDED
#define I386_PUBLIC_MATH_INCLUDED
//Retained software F64 and original integer-multiple providers.
public _extern _ROUND F64 Round(F64 value);
public _extern _TRUNC F64 Trunc(F64 value);
public _extern _FLOOR F64 Floor(F64 value);
public _extern _CEIL F64 Ceil(F64 value);
public _extern _POW10_I64 F64 Pow10I64(I64 exponent);
public _extern _LN F64 Ln(F64 value);
public _extern _LOG10 F64 Log10(F64 value);
public _extern _LOG2 F64 Log2(F64 value);
public _extern _FLOOR_U64 U64 FloorU64(U64 num,U64 to);
public _extern _CEIL_U64 U64 CeilU64(U64 num,U64 to);
public _extern _ROUND_I64 I64 RoundI64(I64 num,I64 to);
public _extern _FLOOR_I64 I64 FloorI64(I64 num,I64 to);
public _extern _CEIL_I64 I64 CeilI64(I64 num,I64 to);
public _extern _RAND_U16 U16 RandU16();
public _extern _DIST_SQR_I64 I64 DistSqrI64(I64 x1,I64 y1,I64 x2,I64 y2);
public _extern _SIN F64 Sin(F64 value);
public _extern _COS F64 Cos(F64 value);
public _extern _ARG F64 Arg(F64 x,F64 y);
#endif
