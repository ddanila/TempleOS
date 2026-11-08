#include "/Compiler/AsmHashTableCore.HC"

U0 AsmHashLoad()
{
  I64 i;CInternalType *tmpit;CHashClass *tmpc;
  cmp.asm_hash=AsmHashTableLoad("OpCodes.DD");
  for (i=0;i<INTERNAL_TYPES_NUM;i++) {
    tmpit=&internal_types_table[i];
    tmpc=PrsClassNew;
    InternalTypeSet(tmpc,i);
    tmpc->str=AStrNew(tmpit->name);
    HashAdd(tmpc,cmp.asm_hash);
    cmp.internal_types[tmpc->raw_type]=tmpc;
  }
  adam_task->hash_table->next=cmp.asm_hash;
}
