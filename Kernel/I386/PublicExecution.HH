#ifndef I386_PUBLIC_EXECUTION_INCLUDED
#define I386_PUBLIC_EXECUTION_INCLUDED
#include "/Kernel/LexHashContextTypes.HH"
#include "/Kernel/CompilerCommandFlag.HH"
public _extern _EXE_PUTS I64 ExePutS(U8 *buf,U8 *filename=NULL,
  I64 ccf_flags=0,CLexHashTableContext *htc=NULL);
public _extern _ADAM I64 Adam(U8 *fmt,...);
public _extern _ADAM_FILE I64 AdamFile(U8 *filename,Bool warn_ext=TRUE);
public _extern _EXE_PUTS2 I64 ExePutS2(U8 *buf,U8 *filename=NULL,I64 ccf_flags=0);
public _extern _EXE_FILE2 I64 ExeFile2(U8 *name,I64 ccf_flags=0);
public _extern _EXE_FILE I64 ExeFile(U8 *name,I64 ccf_flags=0);
public _extern _EXE_PRINT I64 ExePrint(U8 *fmt,...);
#endif
