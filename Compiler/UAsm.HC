#include "/Compiler/UAsmCore.HC"

U0 UAsmHashLoad()
{
  CHashOpcode *tmph;
  CInst *tmpins;
  I64 i,j1,j2,k;

  uasm.ins64_arg_mask=0x0880888880+1<<ARGT_ST0+1<<ARGT_STI;
  uasm.signed_arg_mask=1<<ARGT_REL8+1<<ARGT_REL16+1<<ARGT_REL32+
	1<<ARGT_IMM8+1<<ARGT_IMM16+1<<ARGT_IMM32+1<<ARGT_IMM64;
  uasm.mem_arg_mask=1<<ARGT_M8+1<<ARGT_M16+1<<ARGT_M32+1<<ARGT_M64;

  uasm.table_16_32_entries=uasm.table_64_entries=0;
  for (i=0;i<=cmp.asm_hash->mask;i++) {
    tmph=cmp.asm_hash->body[i];
    while (tmph) {
      if (tmph->type==HTT_OPCODE && !(tmph->oc_flags&OCF_ALIAS)) {
	tmpins=&tmph->ins;
	for (k=0;k<tmph->inst_entry_cnt;k++) {
	  uasm.table_16_32_entries++;
	  if (!(tmpins->flags&IEF_NOT_IN_64_BIT))
	    uasm.table_64_entries++;
	  tmpins++;
	}
      }
      tmph=tmph->next;
    }
  }

  j1=j2=0;
  uasm.table_16_32=MAlloc(uasm.table_16_32_entries*sizeof(U8 *));
  uasm.table_64   =MAlloc(uasm.table_64_entries   *sizeof(U8 *));
  for (i=0;i<=cmp.asm_hash->mask;i++) {
    tmph=cmp.asm_hash->body[i];
    while (tmph) {
      if (tmph->type==HTT_OPCODE && !(tmph->oc_flags&OCF_ALIAS)) {
	tmpins=&tmph->ins;
	for (k=0;k<tmph->inst_entry_cnt;k++) {
	  uasm.table_16_32[j1++]=tmpins;
	  if (!(tmpins->flags&IEF_NOT_IN_64_BIT))
	    uasm.table_64[j2++]=tmpins;
	  tmpins++;
	}
      }
      tmph=tmph->next;
    }
  }
  QSortI64(uasm.table_16_32,uasm.table_16_32_entries,&InstEntriesCompare);
  QSortI64(uasm.table_64   ,uasm.table_64_entries   ,&InstEntriesCompare);
}
