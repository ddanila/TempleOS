#ifndef I386_SOFT_F64_INCLUDED
#define I386_SOFT_F64_INCLUDED
//Binary64 bit patterns, integer ABI. Fixed round-to-nearest, ties-to-even.
public extern U64 I386F64Abs(U64 value);
public extern U64 I386F64Sqrt(U64 value);
public extern U64 I386F64Round(U64 value);
public extern U64 I386F64Trunc(U64 value);
public extern U64 I386F64Floor(U64 value);
public extern U64 I386F64Ceil(U64 value);
public extern U64 I386F64Add(U64 a,U64 b);
public extern U64 I386F64Sub(U64 a,U64 b);
public extern U64 I386F64Mul(U64 a,U64 b);
public extern U64 I386F64Div(U64 a,U64 b);
//Truncating remainder: exact finite result, retaining the dividend sign.
public extern U64 I386F64Mod(U64 a,U64 b);
public extern U64 I386F64FromU64(U64 value);
public extern U64 I386F64FromI64(I64 value);
//Compare returns -1, 0, 1, or unordered; it does not raise exception flags.
#define I386_F64_UNORDERED 2
public extern I64 I386F64Compare(U64 a,U64 b);
public extern I64 I386F64ToI64(U64 value);
#endif
