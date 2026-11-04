U0 EndianContract()
{
  I64 i;
  U32 d;
  U64 q;
  for(i=0;i<65536;i++)
    if(EndianU16(i)!=((i&255)<<8|i>>8))throw('Endian',TRUE);
  if(EndianU32(0x12345678)!=0x78563412)throw('Endian',TRUE);
  if(EndianU32(0xFFFFFFFF)!=0xFFFFFFFF)throw('Endian',TRUE);
  if(EndianI64(0x0123456789ABCDEF)!=0xEFCDAB8967452301)throw('Endian',TRUE);
  if(EndianI64(-1)!=-1||EndianI64(0)!=0)throw('Endian',TRUE);
  for(i=0;i<32;i++) {
    d=1<<i;
    if(EndianU32(d)!=(1<<((3-i/8)*8+i%8)))throw('Endian',TRUE);
    if(EndianU32(EndianU32(d))!=d)throw('Endian',TRUE);
  }
  for(i=0;i<64;i++) {
    q=1<<i;
    if(EndianI64(q)!=(1<<((7-i/8)*8+i%8)))throw('Endian',TRUE);
    if(EndianI64(EndianI64(q))!=q)throw('Endian',TRUE);
  }
}
EndianContract;
