//Baseline planar VGA presentation after BIOS mode 0x12 setup.
//Caller owns hardware access: no concurrent VGA register or framebuffer writes.
//The console supplies one presentation owner; IRQ handlers do not touch VGA.
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

public Bool I386VgaRows(U8 *planes,I64 first,I64 count)
{//Existing logical layout: low bit is the left pixel; VGA uses the opposite order.
  U8 *vga=0xA0000,*source,value;
  I64 plane,i,begin,end;
  if(!planes || (planes+0)(U64)>0x100000000-153600 ||
      first<0 || first>480 || count<0 || count>480-first) return FALSE;
  if(!count) return TRUE;
  begin=first*80; end=(first+count)*80;
  for(plane=0;plane<4;plane++) {
    OutU8(0x3C4,2);
    OutU8(0x3C5,1<<plane);
    source=planes+plane*38400;
    for(i=begin;i<end;i++) {
      value=source[i];
      value=(value&0x55)<<1|(value>>1)&0x55;
      value=(value&0x33)<<2|(value>>2)&0x33;
      value=value<<4|value>>4;
      vga[i]=value;
    }
  }
  OutU8(0x3C4,2); OutU8(0x3C5,15);
  return TRUE;
}
public U0 I386VgaPresent(U8 *planes)
{ I386VgaRows(planes,0,480); }
