#ifndef I386_PUBLIC_EXECUTION_INCLUDED
#define I386_PUBLIC_EXECUTION_INCLUDED
#include "/Kernel/LexHashContextTypes.HH"
public _extern _EXE_PUTS I64 ExePutS(U8 *buf,U8 *filename=NULL,
  I64 ccf_flags=0,CLexHashTableContext *htc=NULL);
public _extern _EXE_PRINT I64 ExePrint(U8 *fmt,...);
#endif
