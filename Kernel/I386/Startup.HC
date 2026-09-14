//Disk-loaded AOT startup. No code/data addresses from this image may be retained.
#include "/Kernel/Types.HH"
import U0 KernelLog(U8 *text);
import U0 KernelDisplay();
import I64 kernel_startup_count;
I64 Main()
{
  KernelDisplay;
  kernel_startup_count++;
  KernelLog("STARTUP disk module\n");
  return kernel_startup_count;
}
