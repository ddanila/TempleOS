I64 JRContract(I64 unused)
{
  I64 mask=0;
  if(EndianU16(0x1234)==0x3412)mask|=1;
  if(EndianU32(0x12345678)==0x78563412)mask|=2;
  if(EndianI64(0x0123456789ABCDEF)==0xEFCDAB8967452301)mask|=4;
  if(!EndianU16(0) && !EndianU32(0) && !EndianI64(0))mask|=8;
  if(EndianU16(0xFFFF)==0xFFFF && EndianU32(0xFFFFFFFF)==0xFFFFFFFF && EndianI64(-1)==-1)mask|=16;
  if(EndianU16(EndianU16(0x8042))==0x8042 && EndianU32(EndianU32(0x804201FE))==0x804201FE && EndianI64(EndianI64(0x804201FE10203040))==0x804201FE10203040)mask|=32;
  return mask;
}
