#include "/Compiler/AsmArgumentNames.HH"
#include "/Compiler/AsmHashTableCore.HC"
CHashTable *NativeSystemAsmTypeTable()
{
  CHashTable *table;CHash *entry;I64 bucket;
  for(table=native_jit_support.symbols;table;table=table->next)
    for(bucket=0;bucket<=table->mask;bucket++)
      for(entry=table->body[bucket];entry;entry=entry->next)
        if(entry==cmp.internal_types[RT_I64])return table;
  return NULL;
}
U0 NativeSystemAsmPublish()
{
  CHashTable *table,*cursor,*types=NativeSystemAsmTypeTable(),*old=cmp.asm_hash;
  Bool old_seen=FALSE;U8 *s="PUBLIC ASM loaded\n";
  if(!types)throw('AsmLoad');
  DefineLstLoad("ST_ARG_TYPES",ASM_ARGUMENT_NAMES);
  table=AsmHashTableLoad("::/Compiler/OpCodes.DD");
  for(cursor=native_jit_support.symbols;cursor;cursor=cursor->next)
    if(cursor==old)old_seen=TRUE;
  //Types precede same-name asm keywords. Full instructions precede the boot
  //recognition-only opcode records, which deliberately contain no encodings.
  table->next=types->next;types->next=table;
  if(old && !old_seen) {
    cursor=table;while(cursor->next)cursor=cursor->next;cursor->next=old;
  }
  cmp.asm_hash=native_jit_support.symbols;
  native_jit_support.assembly=&NativeSystemPrsAsmBlk;
  native_jit_support.join=&NativeSystemCmpJoin;
  while(*s)OutU8(0xE9,*s++);
}
if(native_jit_support.asm_stage!=3)throw('AsmLoad');
NativeSystemAsmPublish;
native_jit_support.asm_stage=4;
