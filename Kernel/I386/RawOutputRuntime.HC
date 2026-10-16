#include "/Kernel/VgaPorts.HH"
#include "/Kernel/RunLevelTypes.HH"
//The native boot profile enters BIOS VGA mode 12 before protected mode.
I64 native_raw_run_level=RLF_VGA;
U8 native_raw_reverse_bits[256];
U0 NativeRawInit()
{
  I64 i,j;
  for(i=0;i<256;i++)
    for(j=0;j<8;j++)
      if(Bt(&i,7-j)) LBts(native_raw_reverse_bits+i,j);
}
#define sys_run_level native_raw_run_level
#define rev_bits_table native_raw_reverse_bits
#define I386_RAW_OUTPUT_IRQ 1
#include "/Kernel/RawOutputCore.HC"
U0 NativeRawPutChar(I64 ch)
{//Cache belongs to the kernel heap, independent of the calling task lifetime.
  U32 irq=I386IrqSave;
  if(!text.raw_scrn_image)
    text.raw_scrn_image=I386HeapAlloc(console_config->heap,GR_WIDTH*GR_HEIGHT>>3,TRUE);
  I386IrqRestore(irq);
  if(!text.raw_scrn_image) throw('OutMem');
  RawPutChar(ch);
}
#define RawPutChar NativeRawPutChar
#include "/Kernel/KeyRawOutputCore.HC"
