#ifndef REDSEA_BOOT_TYPES_INCLUDED
#define REDSEA_BOOT_TYPES_INCLUDED
#define MBR_PT_REDSEA	0x88
class CRedSeaBoot
{
  U8	jump_and_nop[3],
	signature,reserved[4]; //MBR_PT_REDSEA=0x88. Distinguish from real FAT32
  I64	drv_offset,	//For CD/DVD image copy.
	sects,
	root_clus,
	bitmap_sects,
	unique_id;
  U8	code[462];
  U16	signature2;	//0xAA55
};
#endif
