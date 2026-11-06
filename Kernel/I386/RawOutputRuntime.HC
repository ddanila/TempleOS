#include "/Kernel/VgaPorts.HH"
#include "/Kernel/RunLevelTypes.HH"
//All stage consumers share the kernel-owned original-width flag record.
#define sys_run_level (*console_config->run_level)
U8 native_raw_reverse_bits[256],native_raw_set_bits[256];
U8 *native_rev_bits_table,*native_set_bits_table;
U0 NativeRawInit()
{
  I64 i,j;
  native_rev_bits_table=native_raw_reverse_bits;
  native_set_bits_table=native_raw_set_bits;
  MemSet(native_raw_reverse_bits,0,256);
  MemSet(native_raw_set_bits,0,256);
  for(i=0;i<256;i++)
    for(j=0;j<8;j++) {
      if(Bt(&i,7-j)) LBts(native_raw_reverse_bits+i,j);
      if(Bt(&i,j))native_raw_set_bits[i]++;
    }
}
U0 NativeRunLevelMark(I64 bit,U8 *stage)
{//Stage flags are shared with the kernel; log while retaining the caller's IF.
  U32 irq=I386IrqSave;
  LBts(&sys_run_level,bit);
  KernelLog("RUN LEVEL ");KernelLog(stage);KernelLog(" ");
  KernelHex(sys_run_level);KernelLog("\n");
  I386IrqRestore(irq);
}
#define rev_bits_table native_rev_bits_table
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
