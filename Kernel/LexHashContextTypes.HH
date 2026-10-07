#ifndef KERNEL_LEX_HASH_CONTEXT_TYPES_INCLUDED
#define KERNEL_LEX_HASH_CONTEXT_TYPES_INCLUDED
#include "/Kernel/HashTypes.HH"
#ifndef CHashFun
extern class CHashFun;
#endif
class CLexHashTableContext
{
  CLexHashTableContext *next;
  I64	old_flags,hash_mask;
  CHashFun *local_var_lst,
	*fun;
  CHashTable *hash_table_lst,
	*define_hash_table,
	*local_hash_table,
	*glbl_hash_table;
};

#endif
