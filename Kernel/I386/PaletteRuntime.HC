//The port runs VGA on one CPU. Preserve the caller's interrupt state while
//using the shared DAC index/data registers; no task switch occurs in a transfer.
U0 GrPaletteColorSet(I64 color_num,CBGR48 bgr48)
{
  U32 irq;
  if(!Bt(&sys_run_level,RLf_VGA))return;
  irq=I386IrqSave;
  OutU8(VGAP_PALETTE_MASK,0xFF);OutU8(VGAP_REG_WRITE,color_num);
  OutU8(VGAP_PALETTE_DATA,bgr48.r>>10);
  OutU8(VGAP_PALETTE_DATA,bgr48.g>>10);
  OutU8(VGAP_PALETTE_DATA,bgr48.b>>10);
  I386IrqRestore(irq);
}
CBGR48 GrPaletteColorGet(I64 color_num)
{
  CBGR48 res=0;
  U32 irq;
  if(!Bt(&sys_run_level,RLf_VGA))return 0;
  irq=I386IrqSave;
  OutU8(VGAP_PALETTE_MASK,0xFF);OutU8(VGAP_REG_READ,color_num);
  res.r=0xFFFF<<10*InU8(VGAP_PALETTE_DATA)/0xFC00;
  res.g=0xFFFF<<10*InU8(VGAP_PALETTE_DATA)/0xFC00;
  res.b=0xFFFF<<10*InU8(VGAP_PALETTE_DATA)/0xFC00;
  I386IrqRestore(irq);
  return res;
}
#include "/Adam/Gr/GrPaletteBulkCore.HC"
