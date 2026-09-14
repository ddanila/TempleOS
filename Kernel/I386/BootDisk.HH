#ifndef I386_BOOT_DISK_INCLUDED
#define I386_BOOT_DISK_INCLUDED
#define I386_BOOT_DISK_INFO_ADDRESS 0x5020
#define I386_BOOT_DISK_INFO_MAGIC 0x44323349
class CI386BootDiskInfo
{
  U32 magic,version,bios_drive,volume_start;
};
#assert sizeof(CI386BootDiskInfo)==16
#endif
