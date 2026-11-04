#ifndef ATAPI_TRACK_TYPES_INCLUDED
#define ATAPI_TRACK_TYPES_INCLUDED
class CATAPITrack
{
  U16	track_info_len;
  U8	track_lo,
	session_lo,
	reserved;
  U16	misc1;
  U8	misc2;
  U32	track_start,
	next_writable,
	free_blks;
  union {
    U32 fixed_packet_size;
    U32 blocking_factor;
  };
  union {
    U32 track_size;
    U32 rzone_end;
  };
  U32	last_recorded;
  U8	track_hi,
	session_hi;
  U16	reserved;
  U32	read_compatibility,
	next_layer_jmp,
	last_layer_jmp;
};
#endif
