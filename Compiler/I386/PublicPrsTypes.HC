//Ordered normal shared-parser stage.
#include "/Compiler/PrsSymbolAllocate.HC"
#include "/Compiler/PrsBinary.HC"
U0 NativeSystemPrsTypes()
{
  U32 *binary=NULL;CHashTable *table=NULL;
  try{
    if(!cmp.asm_hash)table=HashTableNew(32);
    if(!cmp.binary_ops){binary=CAlloc(sizeof(U32)*TK_TKS_NUM);PrsBinaryInit(binary);}
  }catch{Free(binary);if(table)HashTableDel(table);}
  if(table)cmp.asm_hash=table;
  if(binary)cmp.binary_ops=binary;
  if(!cmp.asm_hash || !cmp.binary_ops)throw('PrsLoad');
}
NativeSystemPrsTypes;

if(native_jit_support.prs_stage!=2)throw('PrsLoad');
native_jit_support.prs_stage=3;
