while (!Bt(&sys_run_level,RLf_ADAM_SERVER)) Yield;
extern U0 RedSeaFmt(U8 drv_let,Bool quick=TRUE);
CDrv txt_drive;
CBlkDev txt_device;
U0 TXTGenHome()
{
  txt_drive.dv_signature=DRV_SIGNATURE_VAL;
  txt_drive.drv_let='Z';
  txt_drive.fs_type=FSt_REDSEA;
  txt_drive.bd=&txt_device;
  txt_drive.size=128;
  txt_device.bd_signature=BD_SIGNATURE_VAL;
  txt_device.type=BDT_RAM;
  txt_device.flags=BDF_INITIALIZED;
  txt_device.first_drv_let='Z';
  txt_device.max_blk=127;
  txt_device.blk_size=512;
  txt_device.init_root_dir_blks=1;
  txt_device.RAM_dsk=CAlloc(128*512);
  blkdev.let_to_drv[25]=&txt_drive;
  RedSeaFmt('Z');
  HomeSet("Z:/");
  Drv('T');
}
TXTGenHome;
#include "::/Adam/Opt/Utils/ToTXT.HC"
#include "::/Demo/ToHtmlToTXTDemo/TXTGen.HC"
U0 TXTGenCapture()
{
  I64 bytes;
  U8 *data=FileRead("~/DemoOutPage.TXT",&bytes),*line,*cursor;
  if (!data)
    return;
  line=MStrPrint("EXPORT DemoOutPage.TXT %X %X\n",data,bytes);
  cursor=line;
  while (*cursor) OutU8(0xE9,*cursor++);
  Sleep(1000);
  Free(line);
  Free(data);
  line="DONE txtgen\n";
  while (*line) OutU8(0xE9,*line++);
}
TXTGenCapture;
