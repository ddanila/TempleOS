#ifndef KERNEL_RAW_TYPES_INCLUDED
#define KERNEL_RAW_TYPES_INCLUDED
//See $LK,"ST_RAW_TYPES",A="MN:ST_RAW_TYPES"$
#define RT_I0		2
#define RT_U0		3
#define RT_I8		4
#define RT_U8		5
#define RT_I16		6
#define RT_U16		7
#define RT_I32		8
#define RT_U32		9
#define RT_I64		10
#define RT_PTR		10 //Signed to allow negative err codes. $LK,"DOCM_CANCEL",A="MN:DOCM_CANCEL"$
#define RT_U64		11
#define RT_F32		12 //Not implemented
#define RT_UF32		13 //Not implemented, Fictitious
#define RT_F64		14
#define RT_UF64		15 //Fictitious
#define RT_RTS_NUM	16
#define RTF_UNSIGNED	1
#define RTG_MASK	0xFF

#endif
