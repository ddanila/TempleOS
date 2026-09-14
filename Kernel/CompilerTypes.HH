#ifndef KERNEL_COMPILER_TYPES_INCLUDED
#define KERNEL_COMPILER_TYPES_INCLUDED
#include "/Kernel/SymbolTypes.HH"
#ifndef CAOT
extern class CAOT;
#endif
#ifndef CIntermediateCode
extern class CIntermediateCode;
#endif
#ifndef CDoc
extern class CDoc;
#endif
#ifndef CDocEntry
extern class CDocEntry;
#endif
#help_index "Compiler/Directive"
//Compiler $LK,"Option",A="MN:Option"$()s
//You might need to do #exe {Option();}
//Note: The #exe stmt is lexed-ahead,
//so it takes effect earlier than you might expect.
#define OPTf_ECHO		0x00
#define OPTf_TRACE		0x01
#define OPTf_WARN_UNUSED_VAR	0x10 //Applied to funs, not stmts
#define OPTf_WARN_PAREN		0x11 //Warn unnecessary parens
#define OPTf_WARN_DUP_TYPES	0x12 //Warn dup local var type stmts
#define OPTf_WARN_HEADER_MISMATCH 0x13
#define OPTf_EXTERNS_TO_IMPORTS	0x20
#define OPTf_KEEP_PRIVATE	0x21
#define OPTf_NO_REG_VAR		0x22  //Applied to funs, not stmts
#define OPTf_GLBLS_ON_DATA_HEAP	0x23
//Disable 10-byte float consts for ã,log2_10,log10_2,loge_2
#define OPTf_NO_BUILTIN_CONST	0x24 //Applied to funs, not stmts
#define OPTf_USE_IMM64		0x25 //Not completely implemented

#define OPTF_ECHO		(1<<OPTf_ECHO)

#help_index "Compiler/Intermediate Code"
#include "/Kernel/RawTypes.HH"

#define MDf_STK		8
#define MDf_IMM		9
#define MDf_REG		10
#define MDf_DISP	11
#define MDf_SIB		12
#define MDf_RIP_DISP32	13

#define MDF_NULL	0x0000
#define MDF_STK		0x0100
#define MDF_IMM		0x0200
#define MDF_REG		0x0400
#define MDF_DISP	0x0800
#define MDF_SIB		0x1000
#define MDF_RIP_DISP32	0x2000
#define MDG_MASK	0xFF00
#define MDG_REG_DISP_SIB	(MDF_REG|MDF_DISP|MDF_SIB)
#define MDG_DISP_SIB_RIP	(MDF_DISP|MDF_SIB|MDF_RIP_DISP32)
#define MDG_REG_DISP_SIB_RIP	(MDF_REG|MDG_DISP_SIB_RIP)

#define ICF_RES_TO_F64			0x000000001
#define ICF_RES_TO_INT			0x000000002
#define ICF_ARG1_TO_F64			0x000000004
#define ICF_ARG1_TO_INT			0x000000008
#define ICF_ARG2_TO_F64			0x000000010
#define ICF_ARG2_TO_INT			0x000000020
#define ICF_USE_F64			0x000000040
#define ICF_USE_UNSIGNED		0x000000080
#define ICF_USE_INT			0x000000100 //highest priority
#define ICF_RES_NOT_USED		0x000000200
#define ICF_CODE_FINAL			0x000000400
#define ICF_BY_VAL			0x000000800 //By value, not ref.
#define ICF_SHORT_JMP			0x000001000
#define ICF_PUSH_RES			0x000002000
#define ICF_PASS_TRACE			0x000004000
#define ICF_RES_WAS_STK			0x000008000
#define ICF_ARG1_WAS_STK		0x000010000
#define ICF_ARG2_WAS_STK		0x000020000
#define ICF_PUSH_CMP			0x000040000 //for 50<i<j<=100 exps
#define ICF_POP_CMP			0x000080000 //for 50<i<j<=100 exps
#define ICF_SWAP			0x000100000
#define ICf_DONT_PUSH_FLOAT0		21 // 3bits
#define ICf_DONT_POP_FLOAT0		24 // 3bits
#define ICF_ALT_TEMPLATE		0x008000000
#define ICF_LOCK			0x010000000
#define ICf_LOCK			28
#define ICF_NO_RIP			0x020000000
#define ICF_DEL_PREV_INS		0x040000000
#define ICF_PREV_DELETED		0x080000000
#define ICF_DONT_RESTORE		0x100000000
#define ICG_NO_CVT_MASK			0x1FFFFFF00

#define IC_BODY_SIZE			0x83

#define ECF_HAS_PUSH_CMP		0x01 //for 50<i<j<=100 exps

U16 class CICType
{
  U8	raw_type,mode;
};

class CICArg
{
  CICType type;
  U16	reg; //low is reg, high is index_reg+scale<<6
  I64	disp;
};

class CICTreeLinks
{
  CHashClass *arg1_class,*arg2_class;
  CIntermediateCode *arg1_tree,*arg2_tree;
  CHashClass *class2;
};

class CIntermediateCodeBase
{
  CIntermediateCode *next,*last;
  U16	ic_code,
	ic_precedence;
  I16	ic_cnt,
	ic_last_start;
};

class CIntermediateCode:CIntermediateCodeBase
{
  I64	ic_flags,
	ic_data,
	ic_line;
  CHashClass *ic_class,*ic_class2;
  CICArg arg1,arg2,res;
  U8	arg1_type_pointed_to; //Used for $LK,"IST_ASSIGN",A="MN:IST_ASSIGN"$ and $LK,"IST_DEREF",A="MN:IST_DEREF"$ $LK,"ic_codes",A="MN:intermediate_code_table"$.
  union {
    U8 ic_body[IC_BODY_SIZE];
    //Tree Links are created in OptPass012.  An ADD opcode, for example,
    //points back to its two earlier arg CIntermediateCode's.

    //Tree links get destroyed during Pass789A when they get overwrites
    //by machine code.	(Saves room to union the output machine code buffer
    //with these links, since they are not needed after pass4.

    //Tree links are used during passes 012 and 3 for determining types.
    CICTreeLinks t;
  };
#assert !($$&7)
};

class CPrsStk
{
  I64	ptr,
	stk[255],
	ptr2,
	stk2[255];
};

#define CMT_LABEL		0
#define CMT_ASM_LABEL		1
#define CMT_GOTO_LABEL		2
#define CMT_STR_CONST		3
#define CMT_JMP_TABLE		4
#define CMT_FLOAT_CONSTS	5
#define CMT_ARRAY_DIM		6
#define CMT_HASH_ENTRY		7

#define CMF_POP_CMP		0x01
#define CMF_DEFINED		0x02
#define CMF_I8_JMP_TABLE	0x04
#define CMF_U8_JMP_TABLE	0x08
#define CMF_I16_JMP_TABLE	0x10
#define CMF_U16_JMP_TABLE	0x20

#define CM_CONSTS_NUM		16

class CCodeMisc
{
  CCodeMisc *next,*last,*fwd,*dft,*begin;
  U8	*str;
  U32	type,flags;
  I64	use_cnt;
  U8	*addr;
  union {
    I64 st_len;		//STR_CONST
    I64 num_consts;	//FLOAT_CONSTS
    I64 range;
    I64 rip;		//ASM_LABEL
  }
  union {
    CCodeMisc **jmp_table;
    F64	*float_consts;
    CArrayDim *dim;
    CHash *h;
  };
};

#help_index "Compiler/Assembler"
#define IEF_OP_SIZE16		0x001
#define IEF_OP_SIZE32		0x002
#define IEF_PLUS_OPCODE		0x004
#define IEF_DONT_SWITCH_MODES	0x008
#define IEF_DFT			0x010
#define IEF_NOT_IN_64_BIT	0x020
#define IEF_48_REX		0x040
#define IEF_REX_ONLY_R8_R15	0x080
#define IEF_REX_XOR_LIKE	0x100
#define IEF_STI_LIKE		0x200
#define IEF_ENDING_ZERO		0x400

//Slash value
#define SV_R_REG	8
#define SV_I_REG	9
#define SV_STI_LIKE	10 //$LK,"uasm_slash_val",A="FF:::/Compiler/AsmInit.HC,uasm_slash_val"$ only.
#define SV_NONE		11
class CInst
{
  U8	ins_entry_num, //This entry num in opcode hash entry
	opcode_cnt,
	opcode[4];
  U16	flags;
  U8	slash_val,uasm_slash_val,opcode_modifier,
	arg1,arg2,
	size1,size2,//Size in bits
	pad;
};

//x86 opcodes
#define OC_OP_SIZE_PREFIX	0x66
#define OC_ADDR_SIZE_PREFIX	0x67
#define OC_LOCK_PREFIX		0xF0
#define OC_NOP			0x90
#define OC_BPT			0xCC
#define OC_CALL			0xE8
#define OC_JMP_REL8		0xEB
#define OC_NOP2			(OC_NOP<<8+OC_OP_SIZE_PREFIX)

#define PUSH_C_REGS PUSH RAX PUSH RCX PUSH RDX PUSH RBX PUSH R8 PUSH R9
#define POP_C_REGS POP R9 POP R8 POP RBX POP RDX POP RCX POP RAX

#define PUSH_REGS PUSH RAX PUSH RCX PUSH RDX PUSH RBX PUSH RBP PUSH RSI \
PUSH RDI PUSH R8 PUSH R9 PUSH R10 PUSH R11 PUSH R12 PUSH R13 PUSH R14 PUSH R15
#define POP_REGS POP R15 POP R14 POP R13 POP R12 POP R11 POP R10 POP R9 \
POP R8 POP RDI POP RSI POP RBP POP RBX POP RDX POP RCX POP RAX

#define REG_RAX		0
#define REG_RCX		1
#define REG_RDX		2
#define REG_RBX		3
#define REG_RSP		4
#define REG_RBP		5
#define REG_RSI		6
#define REG_RDI		7
#define REG_R8		8
#define REG_REGS_NUM	16

#define REG_RIP		16	//Used by compiler, not really it's num
//Be careful: RBPu8, RSPu8, RSIu8, RDIu8 are 20-24
#define REG_NONE	32	//noreg flag sets it to this
#define REG_ALLOC	33	//reg flag sets it to this
#define REG_UNDEF	I8_MIN

#define REGG_CLOBBERED		0x013F //RAX,RCX,RDX,RBX,R8
#define REGG_SAVED		0x0030 //RBP,RSP
#define REGG_STK_TMP		0x0200 //R9
#define REGG_LOCAL_VARS		0xCCC0 //RSI,RDI,R10,R11,R14,R15
#define REGG_LOCAL_NON_PTR_VARS	0x3000 //R12,R13

#define AOT_BIN_BLK_BITS 16
#define AOT_BIN_BLK_SIZE (1<<AOT_BIN_BLK_BITS)

class CAOTBinBlk
{
  CAOTBinBlk *next;
  U8	body[AOT_BIN_BLK_SIZE];
};

I64 class CAbsCntsI64
{
  U16	abs_addres, //Only odd/even matters. Cnt of absolute addres in an exp.
	c_addres; //Only odd/even matters. Cnt of C addres in an exp.
  U32	externs; //Only nonzero matters. Some regions have externs banned.
};

class CAsmUndefHash
{//Only place created is $LK,"Exp Parser",A="FF:::/Compiler/PrsExp.HC,sizeof(CAsmUndefHash)"$ when an undef is found in an ASM exp.
  CAsmUndefHash	*next;
  CHashExport	*hash;
};

class CAsmNum
{
  I64	i;
  U8	*machine_code;
  CAsmUndefHash	*local_asm_undef_hash,*glbl_asm_undef_hash;
  CAbsCntsI64 abs_cnts;
};

class CAsmNum2
{
  CAsmNum num;
  I64	U8_cnt,rel;
  Bool	imm_flag;
};

class CAsmIns
{
  CInst *tmpins;
  CAsmNum2 imm,disp;
  I64	U8_cnt,last_opcode_U8,
	REX,ModrM,SIB;
  Bool	has_REX,has_ModrM,has_SIB,
	has_addr_prefix,
	has_operand_prefix,
	is_dft,pad[2];
};

class CAsmArg
{
  CAsmNum num;
  I64	seg,size, //Size in bytes
	reg1,reg2,
	reg1_type,reg2_type,
	scale;
  Bool	indirect,imm_or_off_present,just_seg,pad[5];
};

class CAsmUnresolvedRef
{
  CAsmUnresolvedRef *next;
  I64	type,line_num;
  U8	*machine_code;
  I64	rip,rel_rip;
  CAOT	*aot;
  U8	*str;	//Only for import glbls
  CAsmUndefHash *asm_undef_hash;
  Bool	U8_avail,
	imm_flag;//Only for import glbls
};

//Opcode Modifier
#define OM_NO 0
#define OM_CB 1
#define OM_CW 2
#define OM_CD 3
#define OM_CP 4
#define OM_IB 5
#define OM_IW 6
#define OM_ID 7

#define ARGT_NONE	0
#define ARGT_REL8	1
#define ARGT_REL16	2
#define ARGT_REL32	3

#define ARGT_IMM8	4
#define ARGT_IMM16	5
#define ARGT_IMM32	6
#define ARGT_IMM64	7

#define ARGT_UIMM8	8
#define ARGT_UIMM16	9
#define ARGT_UIMM32	10
#define ARGT_UIMM64	11

#define ARGT_R8		12
#define ARGT_R16	13
#define ARGT_R32	14
#define ARGT_R64	15

#define ARGT_RM8	16
#define ARGT_RM16	17
#define ARGT_RM32	18
#define ARGT_RM64	19

#define ARGT_M8		20
#define ARGT_M16	21
#define ARGT_M32	22
#define ARGT_M64	23

#define ARGT_M1632	24 // Not implemented
#define ARGT_M16N32	25 // Not implemented
#define ARGT_M16N16	26 // Not implemented
#define ARGT_M32N32	27 // Not implemented

#define ARGT_MOFFS8	28
#define ARGT_MOFFS16	29
#define ARGT_MOFFS32	30
#define ARGT_MOFFS64	31

#define ARGT_AL		32
#define ARGT_AX		33
#define ARGT_EAX	34
#define ARGT_RAX	35

#define ARGT_CL		36
#define ARGT_DX		37
#define ARGT_SREG	39

#define ARGT_SS		40
#define ARGT_DS		41
#define ARGT_ES		42
#define ARGT_FS		43

#define ARGT_GS		44
#define ARGT_CS		45
#define ARGT_ST0	46
#define ARGT_STI	47

#define ARGT_MM		48 // Not implemented
#define ARGT_MM32	49 // Not implemented
#define ARGT_MM64	50 // Not implemented
#define ARGT_XMM	51 // Not implemented

#define ARGT_XMM32	52 // Not implemented
#define ARGT_XMM64	53 // Not implemented
#define ARGT_XMM128	54 // Not implemented
#define ARGT_XMM0	55 // Not implemented

#help_index "Compiler/Internal;Hash/System"
#define OCF_ALIAS	1
public class CHashOpcode:CHash
{
  U16	inst_entry_cnt,
	oc_flags,pad[2];
  CInst ins[1];
};

#help_index "Compiler/Intermediate Code"
#define IEF_GOTO_LABEL		1
#define IEF_I386_DATA_EXPORT	2
class CAOTImportExport
{
  CAOTImportExport *next,*last;
  I64	rip,flags;
  CAOT	*aot;
  U8	*str,
	*src_link,
	type,pad[7];
};

#define AAT_ADD_U8		0
#define AAT_SUB_U8		1
#define AAT_ADD_U16		2
#define AAT_SUB_U16		3
#define AAT_ADD_U32		4
#define AAT_SUB_U32		5
#define AAT_ADD_U64		6
#define AAT_SUB_U64		7
class CAOTAbsAddr
{
  CAOTAbsAddr *next;
  I64	rip;
  U8	type,pad[7];
};

class CAOTHeapGlblRef
{
  CAOTHeapGlblRef *next;
  I64	rip;
};

class CAOTHeapGlbl
{
  CAOTHeapGlbl *next;
  U8	*str;
  I64	size;
  CAOTHeapGlblRef *references;
};

class CAOT
{
  CAOT	*next,*last;
  U8	*buf;
  I64	rip,rip2,
	aot_U8s,
	max_align_bits,org;
  CAOT	*parent_aot;
  CAOTImportExport *next_ie,*last_ie;
  CAOTAbsAddr *abss;
  CAOTHeapGlbl *heap_glbls;
};

class CStreamBlk
{
  CStreamBlk *next,*last;
  U8	*body;
};

class CCodeCtrl
{
  CCodeCtrl *coc_next;
  CCodeMisc *coc_next_misc,*coc_last_misc;
  CIntermediateCodeBase	coc_head;
};

#help_index "Compiler/Lex"
#define __DATE__ #exe{StreamPrint("\"%D\"",Now);}
#define __TIME__ #exe{StreamPrint("\"%T\"",Now);}
#define __LINE__ #exe{StreamPrint("%d",\
	Fs->last_cc->lex_include_stk->line_num);}
#define __CMD_LINE__ #exe{StreamPrint("%d",Fs->last_cc->flags&CCF_CMD_LINE &&\
	Fs->last_cc->lex_include_stk->depth<1);}
#define __FILE__ #exe{StreamPrint("\"%s\"",\
	Fs->last_cc->lex_include_stk->full_name);}
#define __DIR__  #exe{StreamDir;}

#define LFSF_DOC	1
#define LFSF_DEFINE	2
class CLexFile
{
  CLexFile *next;
  U8	*buf,
	*buf_ptr;
  I64	line_num,flags;
  U8	*full_name,
	*line_start;
  CDoc	*doc;
  CDocEntry *cur_entry;
  I32	depth;
  U8	last_U16,pad[3];
};

class CAOTCtrl
{
  I64	rip; //Inst ptr
  CAsmArg arg1,arg2;
  CAOTBinBlk *bin;
  I64	num_bin_U8s,
	max_align_bits,org;
  CAsmUnresolvedRef *local_unresolved,*glbl_unresolved;
  CAOTAbsAddr *abss;
  CAOTHeapGlbl *heap_glbls;
  I64	lst_col,lst_last_rip;
  U8	*last_label,*lst_last_line;
  CLexFile *lst_last_lfn;
  I64	seg_size;
  Bool	lst;
};

//Tokens
#define TK_EOF		0
#define TK_SUPERSCRIPT	0x001
#define TK_SUBSCRIPT	0x002
#define TK_NORMALSCRIPT	0x003
#define TK_IDENT	0x100
#define TK_STR		0x101
#define TK_I64		0x102
#define TK_CHAR_CONST	0x103
#define TK_F64		0x104
#define TK_PLUS_PLUS	0x105
#define TK_MINUS_MINUS	0x106
#define TK_DEREFERENCE	0x107
#define TK_DBL_COLON	0x108
#define TK_SHL		0x109
#define TK_SHR		0x10A
#define TK_EQU_EQU	0x10B
#define TK_NOT_EQU	0x10C
#define TK_LESS_EQU	0x10D
#define TK_GREATER_EQU	0x10E
#define TK_AND_AND	0x10F
#define TK_OR_OR	0x110
#define TK_XOR_XOR	0x111
#define TK_SHL_EQU	0x112
#define TK_SHR_EQU	0x113
#define TK_MUL_EQU	0x114
#define TK_DIV_EQU	0x115
#define TK_AND_EQU	0x116
#define TK_OR_EQU	0x117
#define TK_XOR_EQU	0x118
#define TK_ADD_EQU	0x119
#define TK_SUB_EQU	0x11A
#define TK_IF		0x11B
#define TK_IFDEF	0x11C
#define TK_IFNDEF	0x11D
#define TK_IFAOT	0x11E
#define TK_IFJIT	0x11F
#define TK_ENDIF	0x120
#define TK_ELSE		0x121
#define TK_MOD_EQU	0x122
#define TK_DOT_DOT	0x123
#define TK_ELLIPSIS	0x124
#define TK_INS_BIN	0x125
#define TK_INS_BIN_SIZE 0x126
#define TK_TKS_NUM	0x127

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

//CmpCtrl flags
#define CCF_CMD_LINE		0x001
#define CCF_PMT			0x002
#define CCf_PMT			1
#define CCF_QUESTION_HELP	0x004
#define CCF_DONT_FREE_BUF	0x008
#define CCF_NO_DEFINES		0x010
#define CCF_IN_IF		0x020
#define CCF_JUST_LOAD		0x040
#define CCF_KEEP_NEW_LINES	0x080
#define CCF_KEEP_DOT		0x100
#define CCF_KEEP_SIGN_NUM	0x200
#define CCF_KEEP_AT_SIGN	0x400
#define CCF_NO_CHAR_CONST	0x800
#define CCf_PASS_TRACE_PRESENT	12
#define CCF_NOT_CONST		0x0000020000
#define CCF_NO_REG_OPT		0x0000040000
#define CCF_IN_QUOTES		0x0000080000
#define CCF_EXE_BLK		0x0000100000
#define CCF_HAS_MISC_DATA	0x0000200000
#define CCF_HAS_RETURN		0x0000400000
#define CCF_ASM_EXPRESSIONS	0x0000800000
#define CCF_UNRESOLVED		0x0001000000
#define CCF_LOCAL		0x0002000000
#define CCF_FUN_EXP		0x0004000000
#define CCf_FUN_EXP		26
#define CCF_POSTINC		0x0008000000
#define CCF_POSTDEC		0x0010000000
#define CCF_PREINC		0x0020000000
#define CCF_PREDEC		0x0040000000
#define CCF_ARRAY		0x0080000000
#define CCF_RAX			0x0100000000
#define CCF_USE_LAST_U16	0x0200000000
#define CCf_USE_LAST_U16	33
#define CCF_LAST_WAS_DOT	0x0400000000
#define CCF_AOT_COMPILE		0x0800000000
#define CCf_AOT_COMPILE		35
#define CCF_NO_ABSS		0x1000000000
#define CCF_PAREN		0x2000000000
#define CCf_PAREN		37
#define CCF_CLASS_DOL_OFFSET	0x4000000000
#define CCF_DONT_MAKE_RES	0x8000000000
#define CCF_TARGET_I386		0x10000000000
#define CCF_TARGET_HOST_CONST	0x20000000000

public class CCmpCtrl
{
  CCmpCtrl *next,*last;
  I64	token,
	flags,
	cur_i64;
  F64	cur_f64;
  U8	*cur_str;
  I64	cur_str_len,
	class_dol_offset;
  U8	*dollar_buf;
  I64	dollar_cnt;
  U8	*cur_help_idx;
  I64	last_U16,
	min_line,max_line,last_line_num,
	lock_cnt;
  U32	*char_bmp_alpha_numeric;
  CLexHashTableContext htc;
  CHashGeneric *hash_entry;
  CAbsCntsI64 abs_cnts;
  CAsmUndefHash *asm_undef_hash;
  CMemberLst *local_var_entry;
  CCodeMisc *lb_leave;
  U8	*cur_buf_ptr;
  CLexFile *lex_include_stk,
	*lex_prs_stk,
	*fun_lex_file;
  CStreamBlk *next_stream_blk,*last_stream_blk;
  CAOT	*aot;

  I64	pass,opts,pass_trace,saved_pass_trace,
	error_cnt,warning_cnt;

  //For intermediate codes with multiple float ops (int<->float conversions)
  I64	cur_ic_float_op_num,last_ic_float_op_num;
  CIntermediateCode *last_float_op_ic;
  Bool	last_dont_pushable,last_dont_popable,last_float_op_pos,
	dont_push_float,pad[4];

  CCodeCtrl coc;
  CPrsStk *ps;
  CAOTCtrl *aotc;
  I64	aot_depth,pmt_line;
#assert !($$&7)
};

#help_index "Compiler"
public class CCmpGlbls
{
  CHashTable *asm_hash;
  CHashClass *internal_types[RT_RTS_NUM];
  CIntermediateCode ic_nop;
  U32	*dual_U16_tokens1,*dual_U16_tokens2,*dual_U16_tokens3,
	*binary_ops;
  I64	num_reg_vars,num_non_ptr_vars,
	stk_tmps_mask,reg_vars_mask,non_ptr_vars_mask;
  U8	*to_reg_vars_map,*non_ptr_vars_map;
  I64	size_arg_mask[9],
	compiled_lines;
};

#endif
