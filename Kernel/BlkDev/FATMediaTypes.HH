#ifndef FAT_MEDIA_TYPES_INCLUDED
#define FAT_MEDIA_TYPES_INCLUDED
class CFAT32Boot
{
  U8	jump_and_nop[3],
	oem_name[8];
  U16	bytes_per_sect;
  U8	sects_per_clus;
  U16	reserved_sects;
  U8	copies_of_fat;
  U16	max_root_dir_entries,	//Not used
	old_sects_in_drv;	//Not used
  U8	media_desc;		//F64 for hard disk
  U16	old_sects_per_fat,	//Not used
	sects_per_track,
	num_heads;
  U32	hidden_sects,
	sects,
	sects_per_fat;
  U16	flags,
	version;
  U32	root_clus;
  U16	file_system_info_sect,
	backup_boot_sect;
  U8	reserved[12],
	log_drv_num,
	unused,
	ext_signature; //0x29
  U32	serial_num;
  U8	vol_name[11],
	fat_name[8],
	code[420];
  U16	signature;
};

class CFAT32FileInfoSect
{
  U32	signature1;
  U8	unknown[480];
  U32	signature2,
	free_clus,
	most_recently_alloced;
  U8	reserved[12];
  U32	signature3;
};

#endif
