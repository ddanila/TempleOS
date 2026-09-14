#ifndef KERNEL_PATCH_TYPES_INCLUDED
#define KERNEL_PATCH_TYPES_INCLUDED
//$LK,"CAOTImportExport",A="MN:CAOTImportExport"$ Types. Used in PatchTable.
#define IET_END			0
//reserved
#define IET_REL_I0		2 //Fictitious
#define IET_IMM_U0		3 //Fictitious
#define IET_REL_I8		4
#define IET_IMM_U8		5
#define IET_REL_I16		6
#define IET_IMM_U16		7
#define IET_REL_I32		8
#define IET_IMM_U32		9
#define IET_REL_I64		10
#define IET_IMM_I64		11
#define IEF_IMM_NOT_REL		1
//reserved
#define IET_REL32_EXPORT	16
#define IET_IMM32_EXPORT	17
#define IET_REL64_EXPORT	18 //Not implemented
#define IET_IMM64_EXPORT	19 //Not implemented
#define IET_ABS_ADDR		20
#define IET_CODE_HEAP		21 //Not really used
#define IET_ZEROED_CODE_HEAP	22 //Not really used
#define IET_DATA_HEAP		23
#define IET_ZEROED_DATA_HEAP	24 //Not really used
#define IET_MAIN		25
//Private metadata for the i386 bootstrap writer; never legacy BIN records.
#define IET_I386_DATA		26
#define IET_I386_REL32_ADDR	27

#endif
