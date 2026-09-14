#ifndef I386_PIC_PIT_INCLUDED
#define I386_PIC_PIT_INCLUDED
public extern U0 I386PicInit();
public extern U0 I386PicMask(U16 mask);
public extern U16 I386PicMaskGet();
public extern Bool I386PicAccept(I64 irq);
public extern Bool I386PicEoi(I64 irq);
public extern Bool I386PitStart(I64 divisor);
public extern U16 I386PitRead();
#endif
