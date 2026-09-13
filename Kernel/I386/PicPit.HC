#include "/Kernel/I386/Ports.HH"
//All configuration and interrupt callbacks run with IF clear on the single CPU.
U0 I386PicWrite(I64 port,I64 value)
{
  OutU8(port,value);
  InU8(0x80);
}
public U0 I386PicMask(U16 mask)
{//Exact mask; callers unmask master IRQ2 when using slave IRQs.
  I386PicWrite(0xA1,mask>>8);
  I386PicWrite(0x21,mask);
}
public U16 I386PicMaskGet()
{
  I64 low=InU8(0x21),high=InU8(0xA1);
  return low|high<<8;
}
public U0 I386PicInit()
{//Remap away from CPU exceptions and leave all hardware IRQs masked.
  I386PicMask(0xFFFF);
  I386PicWrite(0x20,0x11); I386PicWrite(0xA0,0x11);
  I386PicWrite(0x21,0x20); I386PicWrite(0xA1,0x28);
  I386PicWrite(0x21,4); I386PicWrite(0xA1,2);
  I386PicWrite(0x21,1); I386PicWrite(0xA1,1);
  I386PicMask(0xFFFF);
}
public Bool I386PicAccept(I64 irq)
{//Check spurious IRQ7/15 before dispatch. A spurious slave IRQ still acks the cascade.
  if (irq<0 || irq>15) return FALSE;
  if (irq==7) {
    I386PicWrite(0x20,0x0B);
    return (InU8(0x20)&0x80)!=0;
  }
  if (irq==15) {
    I386PicWrite(0xA0,0x0B);
    if (!(InU8(0xA0)&0x80)) {
      I386PicWrite(0x20,0x20);
      return FALSE;
    }
  }
  return TRUE;
}
public Bool I386PicEoi(I64 irq)
{//Call once at the end of an accepted interrupt, with IF still clear.
  if (irq<0 || irq>15) return FALSE;
  if (irq>=8) I386PicWrite(0xA0,0x20);
  I386PicWrite(0x20,0x20);
  return TRUE;
}
public Bool I386PitStart(I64 divisor)
{//8253-compatible channel 0, binary rate generator; zero encodes divisor 65536.
  if (divisor<2 || divisor>65536) return FALSE;
  OutU8(0x43,0x34);
  OutU8(0x40,divisor);
  OutU8(0x40,divisor>>8);
  return TRUE;
}
public U16 I386PitRead()
{//Latch channel 0, then read low/high bytes in order. Returns the raw 16-bit count.
  I64 low,high;
  OutU8(0x43,0);
  low=InU8(0x40); high=InU8(0x40);
  return low|high<<8;
}
