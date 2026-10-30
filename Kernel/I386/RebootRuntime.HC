U0 Reboot()
{//Single-core native equivalent of the original PC hardware reset.
  I386IrqSave;
  *0x472(U16 *)=0;
  OutU8(0x70,0x8F);
  OutU8(0x71,0);
  OutU8(0x70,0);
  OutU8(0x92,InU8(0x92)|1);
  while(TRUE) { asm { HLT } }
}
