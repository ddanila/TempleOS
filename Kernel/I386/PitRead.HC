#ifndef I386_PIT_READ_FUNCTION
#define I386_PIT_READ_FUNCTION I386PitRead
#endif
public U16 I386_PIT_READ_FUNCTION()
{//Latch channel 0, then read low/high bytes in order. Returns the raw 16-bit count.
  I64 low,high;
  OutU8(0x43,0);
  low=InU8(0x40); high=InU8(0x40);
  return low|high<<8;
}
