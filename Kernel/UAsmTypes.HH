#ifndef UASM_TYPES_INCLUDED
#define UASM_TYPES_INCLUDED
class CUAsmGlbls
{
  CInst **table_16_32,**table_64;
  I64	table_16_32_entries,
	table_64_entries,
	ins64_arg_mask,
	signed_arg_mask,
	mem_arg_mask;
};

#endif
