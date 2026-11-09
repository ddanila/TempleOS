#ifndef I386_PUBLIC_ASSEMBLY_INCLUDED
#define I386_PUBLIC_ASSEMBLY_INCLUDED
#include "/Kernel/I386/PublicCompiler.HH"
public _extern _PRS_ASM_BLOCK U0 PrsAsmBlk(CCmpCtrl *cc,I64 flags);
public _extern _CMP_JOIN CAOT *CmpJoin(CCmpCtrl *cc,I64 flags,U8 *map_name=NULL,U8 map_drive=0);
public _extern _CMP_BUF CAOT *CmpBuf(U8 *buf,U8 *map_name=NULL,I64 *errors=NULL,I64 *warnings=NULL,U8 map_drive=0);
#endif
