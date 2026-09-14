#include "/Compiler/PrsBinary.HC"
#include "/Compiler/LexPunctInit.HC"
#include "/Compiler/InternalTypes.HC"

#include "/Compiler/ICInfo.HC"

U0 CmpLoadDefines()
{
  DefineLstLoad("ST_RAW_TYPES",
	" \0 \0I0\0U0\0I8\0U8\0I16\0U16\0I32\0U32\0I64\0U64\0"
	"F32\0UF32\0F64\0UF64\0");
  DefineLstLoad("ST_NATURAL_TYPES",
	"I8\0U8\0I16\0U16\0I32\0U32\0I64\0U64\0F64\0String\0");
  DefineLstLoad("ST_INT_SIZE_TYPES",
	"I8\0U8\0I16\0U16\0I32\0U32\0I64\0U64\0");
  DefineLstLoad("ST_TY_TYPES","NULL\0STK\0IMM\0REG\0DISP\0SIB\0RIP\0");
  DefineLstLoad("ST_U8_REGS","AL\0CL\0DL\0BL\0AH\0CH\0DH\0BH\0"
	"R8u8\0R9u8\0R10u8\0R11u8\0R12u8\0R13u8\0R14u8\0R15u8\0");
  DefineLstLoad("ST_U8_REX_REGS","AL\0CL\0DL\0BL\0RSPu8\0RBPu8\0RSIu8\0RDIu8\0"
	"R8u8\0R9u8\0R10u8\0R11u8\0R12u8\0R13u8\0R14u8\0R15u8\0");
  DefineLstLoad("ST_U16_REGS","AX\0CX\0DX\0BX\0SP\0BP\0SI\0DI\0"
	"R8u16\0R9u16\0R10u16\0R11u16\0R12u16\0R13u16\0R14u16\0R15u16\0");
  DefineLstLoad("ST_U32_REGS","EAX\0ECX\0EDX\0EBX\0ESP\0EBP\0ESI\0EDI\0"
	"R8u32\0R9u32\0R10u32\0R11u32\0R12u32\0R13u32\0R14u32\0R15u32\0");
  DefineLstLoad("ST_U64_REGS","RAX\0RCX\0RDX\0RBX\0RSP\0RBP\0RSI\0RDI\0"
	"R8\0R9\0R10\0R11\0R12\0R13\0R14\0R15\0");
  DefineLstLoad("ST_MM_REGS","MM0\0MM1\0MM2\0MM3\0MM4\0MM5\0MM6\0MM7\0");
  DefineLstLoad("ST_XMM_REGS",
	"XMM0\0XMM1\0XMM2\0XMM3\0XMM4\0XMM5\0XMM6\0XMM7\0");
  DefineLstLoad("ST_ARG_TYPES","NONE\0REL8\0REL16\0REL32\0"
	"IMM8\0IMM16\0IMM32\0IMM64\0UIMM8\0UIMM16\0UIMM32\0UIMM64\0"
	"R8\0R16\0R32\0R64\0RM8\0RM16\0RM32\0RM64\0"
	"M8\0M16\0M32\0M64\0M1632\0M16N32\0M16N16\0M32N32\0"
	"MOFFS8\0MOFFS16\0MOFFS32\0MOFFS64\0"
	"AL\0AX\0EAX\0RAX\0CL\0DX\0 \0SREG\0"
	"SS\0DS\0ES\0FS\0GS\0CS\0ST0\0STI\0"
	"MM\0MM32\0MM64\0XMM\0XMM32\0XMM64\0XMM128\0XMM0\0");
  DefineLstLoad("ST_SEG_REGS","ES\0CS\0SS\0DS\0FS\0GS\0");
  DefineLstLoad("ST_FSTK_REGS","ST0\0ST1\0ST2\0ST3\0ST4\0ST5\0ST6\0ST7\0");
}

U0 CmpFillTables()
{
  I64 i;
  U32 *d;

  ICInfoInit;
  cmp.to_reg_vars_map=CAlloc(REG_REGS_NUM*sizeof(U8));
  cmp.num_reg_vars=0;
  cmp.reg_vars_mask=REGG_LOCAL_VARS;
  for (i=0;i<REG_REGS_NUM;i++)
    if (Bt(&cmp.reg_vars_mask,i))
      cmp.to_reg_vars_map[cmp.num_reg_vars++]=i;

  cmp.non_ptr_vars_map=CAlloc(REG_REGS_NUM*sizeof(U8));
  cmp.num_non_ptr_vars=0;
  cmp.non_ptr_vars_mask=REGG_LOCAL_NON_PTR_VARS;
  for (i=0;i<REG_REGS_NUM;i++)
    if (Bt(&cmp.non_ptr_vars_mask,i))
      cmp.non_ptr_vars_map[cmp.num_non_ptr_vars++]=i;

  cmp.dual_U16_tokens1=CAlloc(sizeof(U32)*TK_TKS_NUM);
  cmp.dual_U16_tokens2=CAlloc(sizeof(U32)*TK_TKS_NUM);
  cmp.dual_U16_tokens3=CAlloc(sizeof(U32)*TK_TKS_NUM);
  LexPunctInit(cmp.dual_U16_tokens1,cmp.dual_U16_tokens2,cmp.dual_U16_tokens3);

  cmp.binary_ops=d=CAlloc(sizeof(U32)*TK_TKS_NUM);
  PrsBinaryInit(d);
}
