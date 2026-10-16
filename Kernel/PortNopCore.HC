U0 PortNop()
{//Innoculous (reads IRQ Mask) which should take fixed time
//because it's an ISA-bus standard.  It takes 1.0uS-2.0uS.
  InU8(0x21);
}
