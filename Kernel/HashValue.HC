#include "/Kernel/HashValue.HH"
I64 HashTypeNum(CHash *tmph)
{//Return bit num of hash type, limited to just types.
  U32 bits;
  I64 bit=0;
  if (!tmph) return -1;
  bits=tmph->type&HTG_TYPE_MASK;
  if (!bits) return -1;
  while (!(bits&1)) { bits>>=1; bit++; }
  return bit;
}

I64 HashVal(CHash *tmph)
{//Returns most likely desired value.
  switch (HashTypeNum(tmph)) {
    case HTt_EXPORT_SYS_SYM:
      return tmph(CHashExport *)->val;
    case HTt_IMPORT_SYS_SYM:
      return (tmph(CHashImport *)->module_base+0)(U64);
    case HTt_DEFINE_STR:
    case HTt_CLASS:
    case HTt_INTERNAL_TYPE:
    case HTt_WORD:
    case HTt_DICT_WORD:
    case HTt_OPCODE:
    case HTt_HELP_FILE:
      return (tmph+0)(U64);
    case HTt_GLBL_VAR:
      if (tmph(CHashGlblVar *)->flags&GVF_EXTERN)
	return (&tmph(CHashGlblVar *)->data_addr+0)(U64);
      else
	return (tmph(CHashGlblVar *)->data_addr+0)(U64);
    case HTt_FUN:
      if ((tmph(CHashFun *)->flags&(1<<Cf_EXTERN)))
	return (tmph+0)(U64);
      else
	return (tmph(CHashFun *)->exe_addr+0)(U64);
    case HTt_REG:
      return tmph(CHashReg *)->reg_num|tmph(CHashReg *)->reg_type<<8;
    case HTt_KEYWORD:
    case HTt_ASM_KEYWORD:
    case HTt_MODULE:
    case HTt_FILE:
    case HTt_FRAME_PTR:
      return tmph(CHashGeneric *)->user_data0;

    case -1:		//nobound switch
    case HTt_TYPES_NUM: //nobound switch
    default:
      return 0;
  }
}

