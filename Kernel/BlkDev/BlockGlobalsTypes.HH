#ifndef BLOCK_GLOBALS_TYPES_INCLUDED
#define BLOCK_GLOBALS_TYPES_INCLUDED
#define DSK_CACHE_HASH_SIZE	0x2000

class CCacheBlk
{
  CCacheBlk *next_lru,*last_lru;
  CCacheBlk *next_hash,*last_hash;
  CDrv	*dv;
  I64	blk;
  U8	body[BLK_SIZE];
};

#help_index "File/System"
#define DFT_ISO_FILENAME	"::/Tmp/CDDVD.ISO"
#define DFT_ISO_C_FILENAME	"::/Tmp/CDDVD.ISO.C"

public class CBlkDevGlbls
{
  CBlkDev *blkdevs;
  U8	*dft_iso_filename;	//$TX,"\"::/Tmp/CDDVD.ISO\"",D="DFT_ISO_FILENAME"$
  U8	*dft_iso_c_filename;	//$TX,"\"::/Tmp/CDDVD.ISO.C\"",D="DFT_ISO_C_FILENAME"$
  U8	*tmp_filename;
  U8	*home_dir;
  CCacheBlk *cache_base,*cache_ctrl,**cache_hash_table;
  I64	cache_size,read_cnt,write_cnt;
  CDrv	*drvs,*let_to_drv[32];
  I64	mount_ide_auto_cnt,
	ins_base0,ins_base1;	//Install cd/dvd controller.
  U8	boot_drv_let,first_hd_drv_let,first_dvd_drv_let;
  Bool	dvd_boot_is_good,ins_unit,pad[3];
};

#endif
