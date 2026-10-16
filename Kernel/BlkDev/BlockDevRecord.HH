#ifndef BLOCK_DEV_RECORD_INCLUDED
#define BLOCK_DEV_RECORD_INCLUDED
#include "/Kernel/BlkDev/BlockDevTypes.HH"
#ifndef CFile
extern class CFile;
#endif
#ifndef CTask
extern class CTask;
#endif
#define BDF_REMOVABLE		0x001
#define BDF_INITIALIZED		0x002
#define BDF_READ_ONLY		0x004
#define BDF_READ_ONLY_OVERRIDE	0x008
#define BDF_LAST_WAS_WRITE	0x010
#define BDF_READ_CACHE		0x020
#define BDF_FMT			0x040
#define BDF_INIT_IN_PROGRESS	0x080
#define BDF_EXT_SIZE		0x100

#define BDf_REMOVABLE		0
#define BDf_INITIALIZED		1
#define BDf_READ_ONLY		2
#define BDf_READ_ONLY_OVERRIDE	3
#define BDf_LAST_WAS_WRITE	4
#define BDf_READ_CACHE		5
#define BDf_FMT			6
#define BDf_INIT_IN_PROGRESS	7
#define BDf_EXT_SIZE		8

//locked flags
#define BDlf_LOCKED		0

#define BLKDEVS_NUM		26
#define BD_SIGNATURE_VAL	'BDSV'
public class CBlkDev
{
  CBlkDev *lock_fwding; //If two blkdevs on same controller, use just one lock
  I64	locked_flags;
  U32	bd_signature,
	type,flags;
  U8	first_drv_let,unit,pad[2];
  U32	base0,base1,
	blk_size;
  I64	drv_offset,init_root_dir_blks,
	max_blk;
  U16	*dev_id_record;
  U8	*RAM_dsk,
	*file_dsk_name;
  CFile *file_dsk;
  CTask *owning_task;
  F64	last_time;
  U32	max_reads,max_writes;
};
#endif
