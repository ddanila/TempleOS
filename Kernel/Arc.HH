#ifndef ARC_TYPES_INCLUDED
#define ARC_TYPES_INCLUDED
#define ARC_BITS_MAX	12

#define CT_NONE 	1
#define CT_7_BIT	2
#define CT_8_BIT	3
class CArcEntry
{
  CArcEntry *next;
  U16	basecode;
  U8	ch,pad;
  U32	pad;
};

public class CArcCtrl
{
  I64	src_pos,src_size,
	dst_pos,dst_size;
  U8	*src_buf,*dst_buf;
  I64	min_bits,min_table_entry;
  CArcEntry *cur_entry,*next_entry;
  I64	cur_bits_in_use,next_bits_in_use;
  U8	*stk_ptr,*stk_base;
  I64	free_idx,free_limit,
	saved_basecode,
	entry_used,
	last_ch;
  CArcEntry compress[1<<ARC_BITS_MAX],
	*hash[1<<ARC_BITS_MAX];
};

#help_index "Compression"
public class CArcCompress
{
  I64	compressed_size,expanded_size;
  U8	compression_type;
  U0	body;
};

#endif
