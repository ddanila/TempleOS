//Native kernel foundation. Resident HolyC compilation and startup execution are pending.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define U32_MAX 0xFFFFFFFF
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/BootMemory.HH"
#include "/Kernel/I386/BootDisk.HH"
#include "/Kernel/I386/RedSea.HH"
#include "/Kernel/I386/ModuleFile.HH"
#include "/Kernel/I386/A20.HH"
#include "/Kernel/I386/TaskPlatform.HH"
#include "/Kernel/I386/ExceptNative.HH"
#include "/Kernel/I386/Interrupt.HH"
#include "/Kernel/I386/Timer.HH"
#include "/Kernel/I386/Sleep.HH"
#include "/Kernel/I386/Vga.HH"
import U0 i386_idle();
CI386Scheduler kernel_scheduler;
CI386Task kernel_root;
CI386Cpu kernel_cpu;
CI386Heap kernel_heap;
CI386Ata kernel_disk;
CI386RedSea kernel_volume;
CI386Timer kernel_timer;
CI386SleepQueue kernel_sleep;
U8 kernel_gdt[40],kernel_idt[2048];
U8 *kernel_planes;
CI386OwnedTask *kernel_pulse;
I64 kernel_startup_count;
extern U0 KernelLog(U8 *text);
extern U0 KernelHex(U64 value);
extern U0 KernelStop();
extern U0 KernelIrq(CI386IrqFrame *frame);
extern U0 KernelFault(CI386ExceptionFrame *frame);
extern U0 KernelReport(CI386Task *task,I64 ch);
extern U0 KernelFatal(CI386Task *task,I64 status,I64 ch);
extern U0 KernelPulse(I64 unused);
extern U0 KernelDisplay();
extern U0 KernelStorage(CI386BootInfo *info);
extern U0 KernelStartup();
I64 Main(CI386BootInfo *info,I64 unused)
{
  CI386MemRange reserved,arena;
  CI386InterruptServices services;
  KernelLog("START native kernel\n");
  reserved.base=0x88000; reserved.size=32768;
  if(!I386BootArena(info,&reserved,1,&arena) || !(info->flags&2) ||
      info->extended_kib<128 || !I386A20Enable(FALSE) ||
      !I386BootArena(info,&reserved,1,&arena,TRUE) ||
      !I386HeapInit(&kernel_heap,arena.base,arena.size)) KernelStop;
  KernelLog("ARENA "); KernelHex(arena.base); KernelLog(" ");
  KernelHex(arena.size); KernelLog("\n");
  if(!I386TaskPlatformInit(&kernel_scheduler,&kernel_root,&kernel_cpu,
      kernel_gdt,0x88000,32768,&kernel_heap) ||
      !I386ExceptInstallNative(&KernelReport,&KernelFatal)) KernelStop;
  KernelStorage(info);
  I386PicInit;
  services.irq=&KernelIrq; services.exception=&KernelFault;
  if(!I386InterruptInstall(kernel_idt,256,&KernelStop,&services) ||
      !I386TimerInit(&kernel_timer,11932) ||
      !I386SleepInit(&kernel_sleep,&kernel_scheduler)) KernelStop;
  KernelStartup;
  kernel_pulse=I386TaskSpawn(&kernel_scheduler,&kernel_heap,8192,&KernelPulse,0,
    0x18,0x20,4096);
  if(!kernel_pulse) KernelStop;
  KernelLog("READY native kernel foundation\n");
  I386PicMask(0xFFFE);
  while(1) {
    if(kernel_root.next==&kernel_root) I386SchedIdle(&kernel_scheduler,&i386_idle);
    else I386SchedYield(&kernel_scheduler);
  }
}
U0 KernelLog(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}
U0 KernelHex(U64 value)
{
  U8 *digits="0123456789ABCDEF";
  I64 i;
  for(i=60;i>=0;i-=4) OutU8(0xE9,digits[(value>>i)&15]);
}
U0 KernelStop()
{
  asm { CLI }
  KernelLog("FAIL native kernel\n");
  while(1) { asm { HLT } }
}
U0 KernelIrq(CI386IrqFrame *frame)
{
  if(!I386PicAccept(frame->irq)) return;
  if(frame->irq==0) {
    if(!I386TimerStep(&kernel_timer) || !I386SleepTick(&kernel_sleep)) KernelStop;
  }
  I386PicEoi(frame->irq);
}
U0 KernelFault(CI386ExceptionFrame *frame)
{
  KernelLog("FAULT "); KernelHex(frame->vector); KernelLog(" ");
  KernelHex(frame->eip); KernelLog("\n"); KernelStop;
}
U0 KernelReport(CI386Task *task,I64 ch)
{
  KernelLog("THROW "); KernelHex(ch); KernelLog("\n");
}
U0 KernelFatal(CI386Task *task,I64 status,I64 ch)
{
  KernelLog("UNHANDLED "); KernelHex(status); KernelLog(" ");
  KernelHex(ch); KernelLog("\n"); KernelStop;
}
U0 KernelPulse(I64 unused)
{
  I64 pulses=0;
  while(1) {
    if(!I386SleepTicks(&kernel_sleep,25)) KernelStop;
    if(pulses<2) {
      pulses++;
      KernelLog("TICK "); KernelHex(I386TimerTicks(&kernel_timer)); KernelLog("\n");
      if(pulses==2) KernelLog("DONE native kernel startup\n");
    }
  }
}
U0 KernelDisplay()
{
  U8 palette[48];
  I64 color,plane,x,y;
  kernel_planes=I386HeapAlloc(&kernel_heap,153600,TRUE);
  if(!kernel_planes) KernelStop;
  for(color=0;color<16;color++) {
    palette[color*3]=0; palette[color*3+1]=0; palette[color*3+2]=0;
    if(color&4) palette[color*3]=42;
    if(color&2) palette[color*3+1]=42;
    if(color&1) palette[color*3+2]=42;
    if(color&8) {
      palette[color*3]+=21; palette[color*3+1]+=21; palette[color*3+2]+=21;
    }
    if(color==6) palette[color*3+1]=21;
  }
  for(plane=0;plane<4;plane++)
    for(y=0;y<480;y++)
      for(x=0;x<80;x++)
        if((x/5)&(1<<plane)) kernel_planes[plane*38400+y*80+x]=255;
  I386VgaPalette(palette); I386VgaPresent(kernel_planes);
}
#include "/Kernel/I386/BootMemory.HC"
#include "/Kernel/I386/A20.HC"
#include "/Kernel/I386/ModuleFile.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
#include "/Kernel/I386/ExceptRuntime.HC"
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Task.HC"
#include "/Kernel/I386/Segments.HC"
#include "/Kernel/I386/Gdt.HC"
#include "/Kernel/I386/TaskPlatform.HC"
#include "/Kernel/I386/ExceptNative.HC"
#include "/Kernel/I386/Idt.HC"
#include "/Kernel/I386/Interrupt.HC"
#include "/Kernel/I386/PicPit.HC"
#include "/Kernel/I386/Timer.HC"
#include "/Kernel/I386/Sleep.HC"
#include "/Kernel/I386/Vga.HC"

U0 KernelStorage(CI386BootInfo *info)
{//Initial profile: BIOS drive 0x80 is primary IDE master; boot I/O owns the channel.
  CI386BootDiskInfo *boot=I386_BOOT_DISK_INFO_ADDRESS;
  CI386RedSeaEntry entry;
  U8 buffer[256];
  I64 offset=0,count,i;
  U32 hash=2166136261;
  if(boot->magic!=I386_BOOT_DISK_INFO_MAGIC || boot->version!=1 ||
      boot->bios_drive!=0x80 || boot->volume_start<=(info->stage_end-info->stage_begin)/512 ||
      !I386AtaIdentify(&kernel_disk,0,0) ||
      !I386RedSeaMount(&kernel_volume,&kernel_disk,boot->volume_start)) KernelStop;
  KernelLog("REDSEA "); KernelHex(kernel_volume.start); KernelLog(" ");
  KernelHex(kernel_volume.sectors); KernelLog("\n");
  if(I386RedSeaFind(&kernel_volume,kernel_volume.root,"Kernel",&entry)!=1 ||
      !(entry.attr&0x10) || I386RedSeaFind(&kernel_volume,entry.block,"I386",&entry)!=1 ||
      !(entry.attr&0x10) || I386RedSeaFind(&kernel_volume,entry.block,"Kernel.HC",&entry)!=1 ||
      (entry.attr&0x310) || entry.size<1) KernelStop;
  while(offset<entry.size) {
    count=I386RedSeaRead(&kernel_volume,&entry,offset,buffer,256);
    if(count<1) KernelStop;
    for(i=0;i<count;i++) hash=(hash^buffer[i])*16777619;
    offset+=count;
  }
  KernelLog("SOURCE "); KernelHex(entry.size); KernelLog(" ");
  KernelHex(hash); KernelLog("\n");
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"

U0 KernelStartup()
{//Startup owns ATA and the heap with IF clear. No module callbacks may survive return.
  CI386RedSeaEntry file;
  CI386ModuleBinding bindings[3];
  U8 *image;
  I64 (*entry)();
  I64 used=kernel_heap.used,allocations=kernel_heap.allocations;
  I64 transient,after,result;
  if(I386RedSeaFind(&kernel_volume,kernel_volume.root,"Modules",&file)!=1 ||
      !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"I386",&file)!=1 ||
      !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"Startup.t32m",&file)!=1)
    KernelStop;
  bindings[0].name="KernelLog"; bindings[0].kind=1;
  bindings[0].address=(&KernelLog+0)(U64);
  bindings[1].name="KernelDisplay"; bindings[1].kind=1;
  bindings[1].address=(&KernelDisplay+0)(U64);
  bindings[2].name="kernel_startup_count"; bindings[2].kind=3;
  bindings[2].address=(&kernel_startup_count+0)(U64);
  image=I386RedSeaLoadBound(&kernel_volume,&file,&kernel_heap,"Main",bindings,3);
  if(!image || kernel_heap.allocations!=allocations+1) KernelStop;
  transient=kernel_heap.used-used;
  entry=image;
  result=(*entry)();
  after=kernel_heap.used; allocations=kernel_heap.allocations;
  if(result!=1 || kernel_startup_count!=1 || !kernel_planes || transient<=0 ||
      !I386HeapFree(&kernel_heap,image) || kernel_heap.used!=after-transient ||
      kernel_heap.allocations!=allocations-1 || !I386HeapValid(&kernel_heap)) KernelStop;
  KernelLog("MODULE "); KernelHex(result); KernelLog(" ");
  KernelHex(transient); KernelLog("\n");
}
