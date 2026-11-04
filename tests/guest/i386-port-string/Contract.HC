U0 PortStringContract()
{
  U8 buf[20],saved;
  I64 i,expected;
  RepInU8(NULL,0,0x1234);RepInU16(NULL,0,0x1234);
  RepInU32(NULL,0,0x1234);RepOutU8(NULL,0,0x1234);
  RepOutU16(NULL,0,0x1234);RepOutU32(NULL,0,0x1234);
  MemSet(buf,0x5A,20);RepInU8(buf+1,3,0x1234);
  for(i=0;i<20;i++) {
    expected=0x5A;if(1<=i<4)expected=0xFF;
    if(buf[i]!=expected)throw('PortIO',TRUE);
  }
  MemSet(buf,0x5A,20);RepInU16(buf+1,3,0x1234);
  for(i=0;i<20;i++) {
    expected=0x5A;if(1<=i<7)expected=0xFF;
    if(buf[i]!=expected)throw('PortIO',TRUE);
  }
  MemSet(buf,0x5A,20);RepInU32(buf+1,3,0x1234);
  for(i=0;i<20;i++) {
    expected=0x5A;if(1<=i<13)expected=0xFF;
    if(buf[i]!=expected)throw('PortIO',TRUE);
  }
  //Only the low byte is observable at the UART scratch register.
  //Distinct elements test the count and buffer stride for each output width.
  for(i=0;i<20;i++)buf[i]=0x12+i*0x11;
  saved=InU8(0x3FF);
  RepOutU8(buf,2,0x3FF);
  if(InU8(0x3FF)!=buf[1])throw('PortIO',TRUE);
  RepOutU16(buf,2,0x3FF);
  if(InU8(0x3FF)!=buf[2])throw('PortIO',TRUE);
  RepOutU32(buf,2,0x3FF);
  if(InU8(0x3FF)!=buf[4])throw('PortIO',TRUE);
  OutU8(0x3FF,saved);
  for(i=0;i<20;i++)
    if(buf[i]!=((0x12+i*0x11)&0xFF))throw('PortIO',TRUE);
}
PortStringContract;
