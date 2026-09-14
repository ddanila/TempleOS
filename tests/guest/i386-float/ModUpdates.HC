I64 mod_picks;
F64 mod_cell;
I64 mod_whole;
F64 *ModPick() { mod_picks++; return &mod_cell; }
I64 *ModPickWhole() { mod_picks++; return &mod_whole; }
I64 CheckModUpdates()
{
  F64 a=17.5,b=2.5,result;
  I64 whole=17,returned;
  I8 narrow=-127;
  U8 byte_value=250;
  U64 wide=0xFFFFFFFFFFFFFFFF,bits;
  result=a%whole; if(result(U64)!=0x3FE0000000000000) return 1;
  result=whole%b; if(result(U64)!=0x4000000000000000) return 2;
  a%=whole; if(a(U64)!=0x3FE0000000000000) return 3;
  returned=(whole%=b); if(whole!=2 || returned!=2) return 4;
  narrow%=b; if(narrow!=-2) return 5;
  a=10.5; byte_value%=a; if(byte_value!=8) return 6;
  wide%=b; if(wide!=0xFFFFFFFFFFFFFFFF) return 7;
  mod_cell=-17.5; mod_picks=0; result=(*ModPick())%=b;
  if(mod_picks!=1 || mod_cell(U64)!=0x8000000000000000 || result(U64)!=mod_cell(U64)) return 8;
  mod_whole=17; returned=(*ModPickWhole())%=b;
  if(mod_picks!=2 || mod_whole!=2 || returned!=2) return 9;
  whole=0x1000000000000001; b=3.0; whole%=b; if(whole!=1) return 10;
  bits=0x7FF8000000001234; b=bits(F64); whole=7; whole%=b;
  if(whole!=0x8000000000000000) return 11;
  return 0;
}
