#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/Float.HH"
F64 cell;
I64 picks,mixed_cell;
extern I64 CheckConditions();
extern I64 CheckChains(Bool native);
extern I64 ConditionNotArithmetic(F64 a);
extern I64 *PickWhole();
extern F64 *Pick();
extern F64 Add(F64 a,F64 b);
extern F64 Sub(F64 a,F64 b);
extern F64 Mul(F64 a,F64 b);
extern F64 Div(F64 a,F64 b);
extern F64 Neg(F64 a);
extern F64 Store(F64 *p,F64 value);
extern F64 LateAdd(F64 a,F64 b);
extern F64 Literal();
extern F64 ReturnFloat(I64 value);
extern I64 ReturnInt(F64 value);
I64 Main(I64 unused_a,I64 unused_b)
{
  F64 a=1.5,b=2.0,c,old,*p=&cell;
  F64 (*fn)(F64 x,F64 y);
  U64 bits;
  I64 whole,old_whole;
  I8 narrow;
  U8 byte_value;
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
  c=a; c+=b; if (c(U64)!=0x400C000000000000) return 13;
  c-=b; if (c(U64)!=a(U64)) return 14;
  c*=b; if (c(U64)!=0x4008000000000000) return 15;
  c/=b; if (c(U64)!=a(U64)) return 16;
  old=c++; if (old(U64)!=a(U64) || c(U64)!=0x4004000000000000) return 17;
  old=c--; if (old(U64)!=0x4004000000000000 || c(U64)!=a(U64)) return 18;
  old=++c; if (old(U64)!=c(U64) || c(U64)!=0x4004000000000000) return 19;
  old=--c; if (old(U64)!=c(U64) || c(U64)!=a(U64)) return 20;
  cell=a; picks=0; old=(*Pick())+=b;
  if (picks!=1 || old(U64)!=cell(U64) || cell(U64)!=0x400C000000000000) return 21;
  old=(*Pick())/=b;
  if (picks!=2 || old(U64)!=cell(U64) || cell(U64)!=0x3FFC000000000000) return 22;
  old=(*Pick())++;
  if (picks!=3 || old(U64)!=0x3FFC000000000000 || cell(U64)!=0x4006000000000000) return 23;
  old=--(*Pick());
  if (picks!=4 || old(U64)!=cell(U64) || cell(U64)!=0x3FFC000000000000) return 24;
  bits=0x8000000000000000; c=bits(F64); old=c++;
  if (old(U64)!=bits || c(U64)!=0x3FF0000000000000) return 25;
  bits=0x7FF0000000000001; c=bits(F64); old=c++;
  if (old(U64)!=bits || c(U64)!=0x7FF8000000000001) return 26;
  bits=0x4340000000000000; c=bits(F64); old=++c;
  if (old(U64)!=bits || c(U64)!=bits) return 27;
  c=ToF64(a); if (c(U64)!=a(U64)) return 28;
  whole=0x1000000000000001;
  if (ToI64(whole)!=whole) return 29;
  whole=17; if (ToI64(ToF64(whole))!=whole) return 30;
  c=ToF64(ToI64(a)); if (c(U64)!=0x3FF0000000000000) return 31;
  whole=2; c=a+whole; if (c(U64)!=0x400C000000000000) return 32;
  c=whole-a; if (c(U64)!=0x3FE0000000000000) return 33;
  c=whole/a; if (c(U64)!=0x3FF5555555555555) return 34;
  if (!(a<whole) || whole<a) return 35;
  c=whole; if (c(U64)!=b(U64)) return 36;
  whole=a; if (whole!=1) return 37;
  whole=2; c=a; c+=whole; if (c(U64)!=0x400C000000000000) return 38;
  c=Add(whole,a); if (c(U64)!=0x400C000000000000) return 39;
  c=ReturnFloat(whole); if (c(U64)!=b(U64)) return 40;
  if (ReturnInt(a)!=1 || ReturnInt(-a)!=-1) return 41;
  c=ReturnFloat(a); if (c(U64)!=0x3FF0000000000000) return 42;
  whole=ReturnInt(whole); if (whole!=2) return 43;
  bits=0xFFFFFFFFFFFFFFFF; c=bits;
  if (c(U64)!=0xBFF0000000000000) return 44;
  c=(a<whole)+0.5; if (c(U64)!=a(U64)) return 45;
  c=(!(a<whole))+whole; if (c(U64)!=b(U64)) return 46;
  c=(a<whole && whole>a)+0.5; if (c(U64)!=a(U64)) return 47;
  c=(a>whole && whole>a)+0.5; if (c(U64)!=0x3FE0000000000000) return 48;
  c=(a<whole || a>whole)+0.5; if (c(U64)!=a(U64)) return 49;
  c=2.5; whole=7; whole+=c; if (whole!=9) return 50;
  whole-=c; if (whole!=6) return 51;
  whole*=c; if (whole!=15) return 52;
  whole/=c; if (whole!=6) return 53;
  old_whole=(whole+=c); if (whole!=8 || old_whole!=8) return 54;
  whole=-7; whole+=c; if (whole!=-4) return 55;
  narrow=-127; narrow-=c; if (narrow!=127) return 56;
  byte_value=250; c=10.5; byte_value+=c; if (byte_value!=4) return 57;
  bits=0xFFFFFFFFFFFFFFFF; c=2.5; bits+=c; if (bits!=1) return 58;
  picks=0; mixed_cell=7; old_whole=(*PickWhole())+=c;
  if (picks!=1 || mixed_cell!=9 || old_whole!=9) return 59;
  old_whole=(*PickWhole())/=c;
  if (picks!=2 || mixed_cell!=3 || old_whole!=3) return 60;
  bits=0x7FF8000000001234; c=bits(F64); whole=7; whole+=c;
  if (whole!=0x8000000000000000) return 61;
  c=0.0; if (ConditionNotArithmetic(c)!=3) return 62;
  whole=CheckConditions(); if (whole) return 1000+whole;
  whole=CheckChains(TRUE); if (whole) return 2000+whole;
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
F64 *Pick() { picks++; return &cell; }
F64 ReturnFloat(I64 value) { return value; }
I64 ReturnInt(F64 value) { return value; }
I64 *PickWhole() { picks++; return &mixed_cell; }

#include "T:/Conditions.HC"

#include "T:/Chains.HC"
