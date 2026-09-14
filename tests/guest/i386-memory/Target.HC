#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/BootMemory.HH"
#include "/Kernel/I386/BootDisk.HH"
extern U0 Reset(CI386BootInfo *info);
extern Bool Rejected(CI386BootInfo *info,CI386MemRange *reserved,I64 count);
I64 Main(I64 a,I64 b)
{
  CI386BootInfo info,*actual=I386_BOOT_INFO_ADDRESS;
  CI386BootDiskInfo *disk_info=I386_BOOT_DISK_INFO_ADDRESS;
  CI386MemRange r[3],out;
  I64 i;
  if(disk_info->magic!=I386_BOOT_DISK_INFO_MAGIC || disk_info->version!=1 ||
      disk_info->bios_drive!=0x80 || disk_info->volume_start) return 30;
  if (actual->magic!=I386_BOOT_INFO_MAGIC || actual->stage_end!=0x20000 ||
      actual->conventional_kib<576 || actual->conventional_kib>640 ||
      !I386BootArena(actual,0,0,&out)) return 1;
  if (actual->flags!=a || (a==1 && actual->extended_kib) ||
      (a==3 && (!actual->extended_kib || actual->extended_kib>7168))) return 29;
  Reset(&info);
  if (!I386BootArena(&info,0,0,&out) || out.base!=0x20000 || out.size!=0x80000) return 2;
  info.ebda_base=0x9FC00;
  if (!I386BootArena(&info,0,0,&out) || out.base!=0x20000 || out.size!=0x7FC00) return 3;
  info.stage_end=0x30000;
  r[0].base=0x70000; r[0].size=0x20000;
  if (!I386BootArena(&info,r,1,&out) || out.base!=0x30000 || out.size!=0x40000) return 4;
  //Unsorted overlapping reservations must be treated as their union.
  info.stage_end=0x20000;
  r[0].base=0x50000; r[0].size=0x10000;
  r[1].base=0x30000; r[1].size=0x10000;
  r[2].base=0x38000; r[2].size=0x18000;
  if (!I386BootArena(&info,r,3,&out) || out.base!=0x60000 || out.size!=0x3FC00) return 5;
  Reset(&info);
  r[0].base=0x20001; r[0].size=1;
  if (!I386BootArena(&info,r,1,&out) || out.base!=0x20008 || out.size!=0x7FFF8) return 6;
  r[0].base=0; r[0].size=0xA0000;
  if (!Rejected(&info,r,1)) return 7;
  r[0].base=0xFFFFF000; r[0].size=0x1000;
  if (!I386BootArena(&info,r,1,&out) || out.base!=0x20000 || out.size!=0x80000) return 8;
  r[0].size=0x1001;
  if (!Rejected(&info,r,1)) return 9;
  r[0].size=0;
  if (!Rejected(&info,r,1) || !Rejected(&info,0,1) || !Rejected(&info,r,-1) ||
      !Rejected(&info,r,129) || !Rejected(0,0,0) || I386BootArena(&info,0,0,0)) return 10;
  for (i=0;i<13;i++) {
    Reset(&info);
    if (i==0) info.magic=0;
    if (i==1) info.version=2;
    if (i==2) info.flags=0;
    if (i==3) info.flags=5;
    if (i==4) info.conventional_kib=0;
    if (i==5) info.conventional_kib=641;
    if (i==6) info.extended_kib=1;
    if (i==7) { info.flags=3; info.extended_kib=65536; }
    if (i==8) info.ebda_base=0x9FC01;
    if (i==9) info.ebda_base=0xA0010;
    if (i==10) info.stage_begin=0;
    if (i==11) info.stage_end=0x10000;
    if (i==12) info.stage_end=0x20008;
    if (!Rejected(&info,0,0)) return 11+i;
  }
  Reset(&info);
  info.flags=3; info.extended_kib=65535;
  //Extended memory is informative only; it cannot expand this arena past VGA.
  if (!I386BootArena(&info,0,0,&out) || out.base!=0x20000 || out.size!=0x80000) return 24;
  info.conventional_kib=512;
  if (!I386BootArena(&info,0,0,&out) || out.base!=0x20000 || out.size!=0x60000) return 25;
  info.ebda_base=0x10000;
  if (!Rejected(&info,0,0)) return 26;
  Reset(&info);
  //Equal gaps choose the first, and sub-allocation-sized gaps fail.
  r[0].base=0x30000; r[0].size=0x10000;
  r[1].base=0x50000; r[1].size=0x50000;
  if (!I386BootArena(&info,r,2,&out) || out.base!=0x20000 || out.size!=0x10000) return 27;
  r[0].base=0x20010; r[0].size=0x7FFF0;
  if (!Rejected(&info,r,1)) return 28;
  Reset(&info);
  info.flags=3; info.extended_kib=65535;
  if (!I386BootArena(&info,0,0,&out,TRUE) || out.base!=0x110000 || out.size!=0xDF0000) return 30;
  r[0].base=0x200000; r[0].size=0xD00000;
  if (!I386BootArena(&info,r,1,&out,TRUE) || out.base!=0x110000 || out.size!=0xF0000) return 31;
  r[0].base=0x100000; r[0].size=0xE00000;
  if (!I386BootArena(&info,r,1,&out,TRUE) || out.base!=0x20000 || out.size!=0x80000) return 32;
  info.flags=1; info.extended_kib=0;
  if (!I386BootArena(&info,0,0,&out,TRUE) || out.base!=0x20000 || out.size!=0x80000) return 33;
  info.flags=3; info.extended_kib=64;
  if (!I386BootArena(&info,0,0,&out,TRUE) || out.base!=0x20000 || out.size!=0x80000) return 34;
  return 0;
}
U0 Reset(CI386BootInfo *info)
{
  info->magic=I386_BOOT_INFO_MAGIC; info->version=1;
  info->conventional_kib=640; info->extended_kib=0; info->ebda_base=0;
  info->stage_begin=0x10000; info->stage_end=0x20000; info->flags=1;
}
Bool Rejected(CI386BootInfo *info,CI386MemRange *reserved,I64 count)
{
  CI386MemRange out;
  out.base=0x12345678; out.size=0x87654321;
  return !I386BootArena(info,reserved,count,&out) &&
    out.base==0x12345678 && out.size==0x87654321;
}
#include "/Kernel/I386/BootMemory.HC"
