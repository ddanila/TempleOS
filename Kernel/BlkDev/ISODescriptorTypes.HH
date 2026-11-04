#ifndef ISO_DESCRIPTOR_TYPES_INCLUDED
#define ISO_DESCRIPTOR_TYPES_INCLUDED
class CPalindromeU16
{
  U16	little,big;
};

class CPalindromeU32
{
  U32	little,big;
};

//ISO9660
#define ISOT_BOOT_RECORD	0
#define ISOT_PRI_VOL_DESC	1
#define ISOT_SUPPLEMENTARY_DESC	2
#define ISOT_VOL_DRV_DESC	3
#define ISOT_TERMINATOR		255

class CISODirEntry
{
  U8 pad[2];
  CPalindromeU32 loc;
  U8 pad[24];
};

class CISOPriDesc
{
  U8	type,
	id[5],
	version,
	pad[73];
  CPalindromeU32 vol_space_size;
  U8	pad[32];
  CPalindromeU16 vol_set_size;
  CPalindromeU16 vol_seq_num;
  CPalindromeU16 log_block_size;
  U8	pad[20];
  CISODirEntry root_dir_record;
  U8	pad[128],
	publisher_id[128],
	pad[435],
	file_structure_version,
	pad[1166];
};
#endif
