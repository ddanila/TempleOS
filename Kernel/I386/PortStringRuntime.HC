//Repeated port transfers for the native eight-byte-argument ABI.
//Transfer count is in elements, with no scheduler yields between accesses.
U0 RepInU8(U8 *buf,I64 cnt,I64 port)
{
  while(cnt--) {
    *buf(U8 *)=InU8(port);
    buf+=1;
  }
}
U0 RepInU16(U8 *buf,I64 cnt,I64 port)
{
  while(cnt--) {
    *buf(U16 *)=InU16(port);
    buf+=2;
  }
}
U0 RepInU32(U8 *buf,I64 cnt,I64 port)
{
  while(cnt--) {
    *buf(U32 *)=InU32(port);
    buf+=4;
  }
}
U0 RepOutU8(U8 *buf,I64 cnt,I64 port)
{
  while(cnt--) {
    OutU8(port,*buf(U8 *));
    buf+=1;
  }
}
U0 RepOutU16(U8 *buf,I64 cnt,I64 port)
{
  while(cnt--) {
    OutU16(port,*buf(U16 *));
    buf+=2;
  }
}
U0 RepOutU32(U8 *buf,I64 cnt,I64 port)
{
  while(cnt--) {
    OutU32(port,*buf(U32 *));
    buf+=4;
  }
}
