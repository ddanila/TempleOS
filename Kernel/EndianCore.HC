U16 EndianU16(U16 d)
{//Swap big<-->little endian.
  I64 res=0;
  res.u8[1]=d.u8[0];
  res.u8[0]=d.u8[1];
  return res;
}

U32 EndianU32(U32 d)
{//Swap big<-->little endian.
  I64 res=0;
  res.u8[3]=d.u8[0];
  res.u8[2]=d.u8[1];
  res.u8[1]=d.u8[2];
  res.u8[0]=d.u8[3];
  return res;
}

I64 EndianI64(I64 d)
{//Swap big<-->little endian.
  U64 res;
  res.u8[7]=d.u8[0];
  res.u8[6]=d.u8[1];
  res.u8[5]=d.u8[2];
  res.u8[4]=d.u8[3];
  res.u8[3]=d.u8[4];
  res.u8[2]=d.u8[5];
  res.u8[1]=d.u8[6];
  res.u8[0]=d.u8[7];
  return res;
}

