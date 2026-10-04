#ifndef I386_PUBLIC_FORMAT_INCLUDED
#define I386_PUBLIC_FORMAT_INCLUDED
public _extern _STR_PRINT_JOIN U8 *StrPrintJoin(U8 *dst,U8 *fmt,I64 argc,I64 *argv);
public _extern _STR_PRINT U8 *StrPrint(U8 *dst,U8 *fmt,...);
public _extern _CAT_PRINT U8 *CatPrint(U8 *dst,U8 *fmt,...);
public _extern _MSTR_PRINT U8 *MStrPrint(U8 *fmt,...);
#endif
