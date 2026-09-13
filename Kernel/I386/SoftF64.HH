#ifndef I386_SOFT_F64_INCLUDED
#define I386_SOFT_F64_INCLUDED
//Binary64 bit patterns, integer ABI. Fixed round-to-nearest, ties-to-even.
public extern U64 I386F64Add(U64 a,U64 b);
public extern U64 I386F64Sub(U64 a,U64 b);
public extern U64 I386F64Mul(U64 a,U64 b);
#endif
