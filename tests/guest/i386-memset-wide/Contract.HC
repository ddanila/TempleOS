I64 MemFillContract()
{
  U8 raw[64],*u8;U16 *u16;U32 *u32;I64 *i64;I64 i,mask=0;Bool ok;
  MemSet(raw,0x5A,64);u8=raw+1;
  ok=MemSetU8(u8,0x1A7,5)==u8+5;
  for(i=0;i<5;i++)if(u8[i]!=0xA7)ok=FALSE;
  if(ok && raw[0]==0x5A && raw[6]==0x5A && !MemSetU8(NULL,1,0))mask|=1;
  MemSet(raw,0x5A,64);u16=(raw+1)(U16 *);
  ok=MemSetU16(u16,0x12345,4)==u16+4;
  for(i=0;i<4;i++)if(u16[i]!=0x2345)ok=FALSE;
  if(ok && raw[0]==0x5A && raw[9]==0x5A && !MemSetU16(NULL,1,0))mask|=2;
  MemSet(raw,0x5A,64);u32=(raw+1)(U32 *);
  ok=MemSetU32(u32,0x123456789,4)==u32+4;
  for(i=0;i<4;i++)if(u32[i]!=0x23456789)ok=FALSE;
  if(ok && raw[0]==0x5A && raw[17]==0x5A && !MemSetU32(NULL,1,0))mask|=4;
  MemSet(raw,0x5A,64);i64=(raw+1)(I64 *);
  ok=MemSetI64(i64,0x123456789ABCDEF0,4)==i64+4;
  for(i=0;i<4;i++)if(i64[i]!=0x123456789ABCDEF0)ok=FALSE;
  if(ok && raw[0]==0x5A && raw[33]==0x5A && !MemSetI64(NULL,1,0))mask|=8;
  return mask;
}
