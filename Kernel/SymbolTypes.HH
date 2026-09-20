#ifndef KERNEL_SYMBOL_TYPES_INCLUDED
#define KERNEL_SYMBOL_TYPES_INCLUDED
#include "/Kernel/HashTypes.HH"
extern class CAOTHeapGlbl;
extern class CAOTImportExport;
extern class CHashClass;
#ifndef CHashFun
extern class CHashFun;
#endif
#help_index "Hash/System"
//Hash table types: $LK,"ST_HTT_TYPES",A="FF:::/Kernel/KDefine.HC,ST_HTT_TYPES"$
#include "/Kernel/HashFlags.HH"

#define KERNEL_MODULE_NAME	"/Kernel/Kernel"

#include "/Kernel/DefineTypes.HH"

#define REGT_NONE	0
#define REGT_R8		1
#define REGT_R16	2
#define REGT_R32	3
#define REGT_R64	4
#define REGT_SEG	5
#define REGT_FSTK	6
#define REGT_MM		7
#define REGT_XMM	8

public class CHashReg:CHash
{
  U8	reg_num,reg_type;
};

public class CHashAC:CHash
{
  I32	num;
  U32	hits;
};

public class CHashExport:CHashSrcSym
{
  I64	val;
};

public class CHashImport:CHashSrcSym
{
  U8	*module_base,
	*module_header_entry;
};

#help_index "Compiler/Internal"
#define PTR_STARS_NUM	4

//Member Lst Flags
#define MLF_DFT_AVAILABLE	1
#define MLF_LASTCLASS		2
#define MLF_STR_DFT_AVAILABLE	4
#define MLF_FUN			8
#define MLF_DOT_DOT_DOT		16
#define MLF_NO_UNUSED_WARN	32
#define MLF_STATIC		64

public class CArrayDim
{
  CArrayDim *next;
  I64	cnt,total_cnt;
};

#define MLMF_IS_STR	1
public class CMemberLstMeta
{
  CMemberLstMeta *next;
  U8	*str;
  I64	flags,
	user_data;
};

public class CMemberLst
{
  CMemberLst *next,*left,*right,
	*left_class_base,*right_class_base; //For finding dup class local vars.
  U8	*str;
  CHashClass *member_class,*member_class_base;
  CMemberLstMeta *meta;
  U32	use_cnt;
  U16	flags;
  I8	reg,pad;
  I64	offset,size;
  CArrayDim dim;
  U8	*static_data;
  union {
    I64	static_data_rip;
    I64 dft_val;
  }
  CHashFun *fun_ptr;
};

class CExternUsage
{
  CExternUsage *next;
  I64	rip;
};

#help_index "Hash/System;Compiler/Internal"
#define Cf_EXTERN		0
#define Cf_INTERNAL_TYPE	1

public class CHashClass:CHashSrcSym
{//See $LK,"PrsClassNew",A="MN:PrsClassNew"$(). base_class of $LK,"CHashFun",A="MN:CHashFun"$
  I64	size,neg_offset;
  U32	member_cnt;
  U8	ptr_stars_cnt,raw_type;
  U16	flags;
  CMemberLst *member_lst_and_root, //Head of linked list and head of tree.
	*member_class_base_root, //For finding dup class local vars.
	*last_in_member_lst;
  CHashClass	*base_class,
	*fwd_class;
};

//Function flags
#define Ff_INTERRUPT		8
#define Ff_HASERRCODE		9
#define Ff_ARGPOP		10
#define Ff_NOARGPOP		11
#define Ff_INTERNAL		12
#define Ff__EXTERN		13
#define Ff_DOT_DOT_DOT		14
#define Ff_RET1			15

public class CHashFun:CHashClass
{//See $LK,"PrsFunNew",A="MN:PrsFunNew"$().
  CHashClass *return_class;
  U32	arg_cnt,pad,
	used_reg_mask,clobbered_reg_mask;
  U8	*exe_addr;
  CExternUsage *ext_lst;
};

//Glbl Var Flags
#define GVF_FUN		1
#define GVF_IMPORT	2
#define GVF_EXTERN	4
#define GVF_DATA_HEAP	8
#define GVF_ALIAS	16
#define GVF_ARRAY	32

public class CHashGlblVar:CHashSrcSym
{
  I64	size,flags;
  CHashClass *var_class;
  CHashFun *fun_ptr;
  CArrayDim dim;
  U8	*data_addr;
  union {
    I64	data_addr_rip;
    CAOTHeapGlbl *heap_glbl;
  }
};
#assert offset(CHashClass.size)==offset(CHashGlblVar.size)

#endif
