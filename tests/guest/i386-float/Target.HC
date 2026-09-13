#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
F64 cell;
extern F64 Add(F64 a,F64 b);
extern F64 Sub(F64 a,F64 b);
extern F64 Mul(F64 a,F64 b);
extern F64 Div(F64 a,F64 b);
extern F64 Neg(F64 a);
extern F64 Store(F64 *p,F64 value);
extern F64 LateAdd(F64 a,F64 b);
extern F64 Literal();
I64 Main(I64 unused_a,I64 unused_b)
{
  F64 a=1.5,b=2.0,c,*p=&cell;
  F64 (*fn)(F64 x,F64 y);
  U64 bits;
  c=Add(a,b); if (c(U64)!=0x400C000000000000) return 1;
  c=Sub(a,b); if (c(U64)!=0xBFE0000000000000) return 2;
  c=Mul(a,b); if (c(U64)!=0x4008000000000000) return 3;
  c=Div(a,b); if (c(U64)!=0x3FE8000000000000) return 4;
  c=Neg(a); if (c(U64)!=0xBFF8000000000000) return 5;
  c=Store(p,a); if (c(U64)!=a(U64) || cell(U64)!=a(U64)) return 6;
  fn=&Sub; c=(*fn)(a,b); if (c(U64)!=0xBFE0000000000000) return 7;
  bits=0x8000000000000000; c=Neg(bits(F64)); if (c(U64)) return 8;
  bits=0x7FF8000000001234; c=Neg(bits(F64)); if (c(U64)!=0xFFF8000000001234) return 9;
  c=Add(Mul(a,b),Div(a,b)); if (c(U64)!=0x400E000000000000) return 10;
  c=LateAdd(a,b); if (c(U64)!=0x400C000000000000) return 11;
  c=Literal(); if (c(U64)!=0x3FF8000000000000) return 12;
  return 0;
}
F64 Add(F64 a,F64 b) { return a+b; }
F64 Sub(F64 a,F64 b) { return a-b; }
F64 Mul(F64 a,F64 b) { return a*b; }
F64 Div(F64 a,F64 b) { return a/b; }
F64 Neg(F64 a) { return -a; }
F64 Store(F64 *p,F64 value) { *p=value; return *p; }
#include "/Kernel/I386/SoftF64.HC"

//The runtime definition already exists here: exercise direct helper relocation.
F64 LateAdd(F64 a,F64 b) { return a+b; }
F64 Literal() { return 1.5; }
