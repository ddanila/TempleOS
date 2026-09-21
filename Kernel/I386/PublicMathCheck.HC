#include "/Kernel/I386/PublicMathVectors.HC"
Bool PublicLogMatches(U64 actual,U64 expected,I64 tolerance)
{
  if((expected&0x7FFFFFFFFFFFFFFF)>=0x7FF0000000000000 || !expected)
    return actual==expected;
  if((actual^expected)>>63) return FALSE;
  if(actual>expected) return actual-expected<=tolerance;
  return expected-actual<=tolerance;
}
I64 PublicMathCheck()
{
  I64 i,count=0;
  U64 *row,bits;
  F64 value,old;
  F64 (*operation)(F64 value);
  operation=&Round;
  for(i=0;i<64;i++) {
    row=public_integral_vectors+i*5;
    value=Round(row[0](F64)); if(value(U64)!=row[1]) return -1000-i;
    value=Trunc(row[0](F64)); if(value(U64)!=row[2]) return -1100-i;
    value=Floor(row[0](F64)); if(value(U64)!=row[3]) return -1200-i;
    value=Ceil(row[0](F64)); if(value(U64)!=row[4]) return -1300-i;
    count+=4;
    row=public_log_vectors+i*4;
    value=Ln(row[0](F64)); if(!PublicLogMatches(value(U64),row[1],1)) return -1400-i;
    value=Log10(row[0](F64)); if(!PublicLogMatches(value(U64),row[2],2)) return -1500-i;
    value=Log2(row[0](F64)); if(!PublicLogMatches(value(U64),row[3],2)) return -1600-i;
    count+=3;
    row=public_multiple_vectors+i*7;
    if(RoundI64(row[0],row[1])!=row[2]) return -1700-i;
    if(FloorI64(row[0],row[1])!=row[3]) return -1800-i;
    if(CeilI64(row[0],row[1])!=row[4]) return -1900-i;
    if(FloorU64(row[0],row[1])!=row[5]) return -2000-i;
    if(CeilU64(row[0],row[1])!=row[6]) return -2100-i;
    count+=5;
  }
  for(i=-308;i<=308;i++) {
    value=Pow10I64(i); if(value(U64)!=public_power_vectors[i+308]) return -3000-i-308;
    value=Floor(Log10(value)); if(value!=ToF64(i)) return -4000-i-308;
    count+=2;
  }
  for(i=-1074;i<=1023;i++) {
    if(i< -1022) bits=1(U64)<<(i+1074);
    else bits=(i+1023)(U64)<<52;
    value=Log2(bits(F64)); if(value!=ToF64(i)) return -5000-i-1074;
    count++;
  }
  value=1.5; old=(*operation)(value++);
  if(old!=2.0 || value!=2.5) return -8000;
  i=10; value=Log10(i++); if(value!=1.0 || i!=11) return -8001;
  value=Floor(Ceil(-1.5))+Trunc(2.75); if(value!=1.0) return -8002;
  value=Pow10I64(-309); if(value(U64)) return -8003;
  value=Pow10I64(309); if(value(U64)!=0x7FF0000000000000) return -8004;
  value=Pow10I64(0x8000000000000000); if(value(U64)) return -8005;
  value=Pow10I64(0x7FFFFFFFFFFFFFFF); if(value(U64)!=0x7FF0000000000000) return -8006;
  return count+7;
}
