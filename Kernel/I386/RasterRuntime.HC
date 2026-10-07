//Complete original raster primitive and its architecture-bound dependencies.
#include "/Kernel/TaskFlags.HH"
#include "/Kernel/I386/ConsolePitRead.HC"
I64 NativeRandClock()
{
  U32 flags=I386IrqSave;
  I64 value=(*console_config->jiffies<<16)^NativeRandPitRead;
  I386IrqRestore(flags);
  return value;
}
#define LIN_CONGRUE_A 6364136223846793005
#define LIN_CONGRUE_C 1442695040888963407
#define GetTSC NativeRandClock
#include "/Kernel/RandU16Core.HC"
#include "/Adam/DistSqrCore.HC"
I64 graphics_raster_bits[256],graphics_raster_colors[256];
#include "/Adam/Gr/GrRasterTablesCore.HC"
U0 NativeRasterSwapU16(U16 *left,U16 *right)
{
  U16 value=*left;
  *left=*right;*right=value;
}
#define SwapU16 NativeRasterSwapU16
#define I386_GR_RECT_EXPLICIT_CONTEXT 1
#include "/Adam/Gr/GrRectCore.HC"
#include "/Adam/Ctrls/WinScrollControlsCore.HC"

U0 NativeRasterSwapI64(I64 *left,I64 *right)
{
  I64 value=*left;
  *left=*right;*right=value;
}
#define SwapI64 NativeRasterSwapI64
