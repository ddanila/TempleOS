U64 f64_mod_oracle[6144];
extern F64 Mod(F64 a,F64 b);
extern F64 LateMod(F64 a,F64 b);
I64 CheckRemainders()
{
  U64 a,b,expected;
  F64 result;
  I64 i,check;
  F64 (*fn)(F64 x,F64 y);
  fn=&Mod;
  for(i=0;i<2048;i++) {
    a=f64_mod_oracle[i*3]; b=f64_mod_oracle[i*3+1]; expected=f64_mod_oracle[i*3+2];
    if(CheckBitwisePair(a,b)) return 10000+i;
    check=CheckMixedBitwisePair(a,b); if(check) return 13000+i*32+check;
    if(I386F64Mod(a,b)!=expected) return 4*i+1;
    result=(*fn)(a(F64),b(F64)); if(result(U64)!=expected) return 4*i+2;
    result=LateMod(a(F64),b(F64)); if(result(U64)!=expected) return 4*i+3;
    result=a(F64); result%=b(F64); if(result(U64)!=expected) return 4*i+4;
  }
  return 0;
}
