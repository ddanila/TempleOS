#ifndef KERNEL_FUN_SEG_TYPES_INCLUDED
#define KERNEL_FUN_SEG_TYPES_INCLUDED
#define FUN_SEG_CACHE_SIZE	256
class CFunSegCache
{
  I64	base,limit;
  F64	time_stamp;
  U8	str[1]; //FUN_SEG_CACHE_STR_LEN
$$=64;
};
#define FUN_SEG_CACHE_STR_LEN	(sizeof(CFunSegCache)-offset(CFunSegCache.str))

#endif
