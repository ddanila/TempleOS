I64 SymbolValueCase(I64 index)
{
  CHashExport ex;
  CHashImport im;
  CHashFun fun;
  CHashGlblVar var;
  CHashReg reg_record;
  CHashGeneric generic;
  I64 value;
  ex.type=HTT_EXPORT_SYS_SYM; ex.val=0x89ABCDEF01234567;
  im.type=HTT_IMPORT_SYS_SYM; im.module_base=0xFEDCBA98;
  fun.type=HTT_FUN; fun.flags=0; fun.exe_addr=0x89ABCDEF;
  var.type=HTT_GLBL_VAR; var.flags=0; var.data_addr=0xEF123456;
  reg_record.type=HTT_REG; reg_record.reg_num=17; reg_record.reg_type=REGT_R32;
  generic.type=0; generic.user_data0=0xFEDCBA9876543210;
  switch(index) {
    case 0: return HashVal(0);
    case 1: return HashVal(&ex);
    case 2: return HashVal(&im);
    case 3: return HashVal(&fun);
    case 4: fun.flags=1<<Cf_EXTERN; return HashVal(&fun)==(&fun+0)(U64);
    case 5: return HashVal(&var);
    case 6: var.flags=GVF_EXTERN; return HashVal(&var)==(&var.data_addr+0)(U64);
    case 7: return HashVal(&reg_record);
    case 8: return HashVal(&generic);
    case 9: generic.type=HTG_FLAGS_MASK; return HashVal(&generic);
    case 10: generic.type=HTT_DEFINE_STR; break;
    case 11: generic.type=HTT_CLASS; break;
    case 12: generic.type=HTT_INTERNAL_TYPE; break;
    case 13: generic.type=HTT_WORD; break;
    case 14: generic.type=HTT_DICT_WORD; break;
    case 15: generic.type=HTT_OPCODE; break;
    case 16: generic.type=HTT_HELP_FILE; break;
    case 17: generic.type=HTT_KEYWORD; return HashVal(&generic);
    case 18: generic.type=HTT_ASM_KEYWORD; return HashVal(&generic);
    case 19: generic.type=HTT_FILE; return HashVal(&generic);
    case 20: generic.type=HTT_MODULE; return HashVal(&generic);
    case 21: generic.type=HTT_FRAME_PTR; return HashVal(&generic);
    case 22: ex.type|=HTT_KEYWORD; return HashVal(&ex);
    case 23: var.flags=GVF_ALIAS; return HashVal(&var);
    case 24: fun.flags=0xFFFF; return HashVal(&fun)==(&fun+0)(U64);
    case 25: generic.type=HTT_KEYWORD|HTF_LOCAL|HTF_PUBLIC; return HashVal(&generic);
    case 26: ex.type|=HTF_PRIVATE|HTF_PUBLIC; return HashVal(&ex);
    case 27: generic.type=0x40000; return HashVal(&generic);
  }
  return HashVal(&generic)==(&generic+0)(U64);
}
