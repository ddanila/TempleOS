#ifndef KERNEL_HASH_TYPES_INCLUDED
#define KERNEL_HASH_TYPES_INCLUDED
public class CHash
{//See $LK,"Hash",A="HI:Hash"$
  CHash	*next;
  U8	*str;
  U32	type,
	use_cnt; // inc'ed every time search found, never dec'ed.
};

public class CHashTable
{
  CHashTable *next;
  I64	mask,locked_flags;
  CHash	**body;
};

public class CHashGeneric:CHash
{
  I64	user_data0,user_data1,user_data2;
};

#endif
