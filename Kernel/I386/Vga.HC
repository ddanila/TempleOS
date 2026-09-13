//Baseline planar VGA presentation after BIOS mode 0x12 setup.
//Caller owns hardware access: no concurrent VGA register or framebuffer writes.
//The native scheduler will provide serialization when integrated.
public U0 I386VgaPalette(U8 *rgb6)
{//16 RGB triples, each component in 0..63, like GrPaletteColorSet's DAC values.
  I64 i;
  InU8(0x3DA);
  for (i=0;i<16;i++) {
    OutU8(0x3C0,i);
    OutU8(0x3C0,i);
  }
  OutU8(0x3C0,0x20);
  OutU8(0x3C0,0);
  InU8(0x3DA);
  OutU8(0x3C6,255);
  OutU8(0x3C8,0);
  for (i=0;i<48;i++) OutU8(0x3C9,rgb6[i]);
}

public U0 I386VgaPresent(U8 *planes)
{//Existing TempleOS planar layout: four 38400-byte planes, low bit = left pixel.
//VGA uses the opposite bit order, as in GrUpdateLine64FlushCache.
  U8 *vga=0xA0000,value;
  I64 plane,i;
  for (plane=0;plane<4;plane++) {
    OutU8(0x3C4,2);
    OutU8(0x3C5,1<<plane);
    for (i=0;i<38400;i++) {
      value=*planes++;
      value=(value&0x55)<<1|(value>>1)&0x55;
      value=(value&0x33)<<2|(value>>2)&0x33;
      value=value<<4|value>>4;
      vga[i]=value;
    }
  }
  OutU8(0x3C4,2);
  OutU8(0x3C5,15);
}
