#ifndef DRIVE_TYPES_INCLUDED
#define DRIVE_TYPES_INCLUDED
#include "/Kernel/DateTypes.HH"
#ifndef CTask
extern class CTask;
#endif
#ifndef CBlkDev
extern class CBlkDev;
#endif
#ifndef CFAT32FileInfoSect
extern class CFAT32FileInfoSect;
#endif
#ifndef CFreeLst
extern class CFreeLst;
#endif
#define DRVS_NUM		26

#define DRV_SIGNATURE_VAL	'DVSV'
public class CDrv
{
//Don't access ->drv_let directly in case a drive has been remapped.
  //Use $LK,"Drv2Let",A="MN:Drv2Let"$().
  I64	locked_flags;
  U32	dv_signature;
  U8	drv_let,pad;
  U16	fs_type;
  I64	drv_offset,
	size,
	prt_num,
	file_system_info_sect,
	fat1,fat2,
	root_clus,
	data_area,
	spc; //sectors per clus
  CDate fat32_local_time_offset;
  CTask *owning_task;
  CBlkDev *bd;

  CFAT32FileInfoSect *fis;
  I64	fat_blk_dirty,
	cur_fat_blk_num;
  U32	*cur_fat_blk;
  CFreeLst *next_free,*last_free;
};

#endif
