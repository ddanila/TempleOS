#ifndef MASTER_BOOT_TYPES_INCLUDED
#define MASTER_BOOT_TYPES_INCLUDED
#define MBR_PT_FAT12	0x01
#define MBR_PT_FAT32a	0x0B
#define MBR_PT_FAT32b	0x0C
#define MBR_PT_FAT32c	0x1B
#define MBR_PT_FAT32d	0x1C
#define MBR_PT_FAT32e	0x8B
#define MBR_PT_FAT32f	0x8C
#define MBR_PT_NTFS	0x07
class CMBRPrt
{
  U8	active,	//0x80=active  0x00=inactive
	start_head;
  U16	start_cyl;
  U8	type,
	end_head;
  U16	end_cyl;
  U32	offset,	//Sects between MBR and first sect
	size;	//Sects in drv
};

class CMasterBoot
{
  U8	code[440];
  U32	media_id;
  U16	zero;
  CMBRPrt p[4];
  U16	signature; //AA55
};
#endif
