#ifndef I386_PUBLIC_FORMAT_INCLUDED
#define I386_PUBLIC_FORMAT_INCLUDED
public _extern _STR_PRINT_JOIN U8 *StrPrintJoin(U8 *dst,U8 *fmt,I64 argc,I64 *argv);
public _extern _STR_PRINT U8 *StrPrint(U8 *dst,U8 *fmt,...);
public _extern _CAT_PRINT U8 *CatPrint(U8 *dst,U8 *fmt,...);
public _extern _MSTR_PRINT U8 *MStrPrint(U8 *fmt,...);
public _extern _PRINT U0 Print(U8 *fmt,...);
public _extern _PUT_S U0 PutS(U8 *text);
public _extern _PUT_CHARS U0 PutChars(U64 chars);
public _extern _STR_SCAN U8 *StrScan(U8 *src,U8 *fmt,...);
public _extern _STR_TO_I64 I64 Str2I64(U8 *src,I64 radix=10,U8 **end_ptr=NULL);
public _extern _STR_TO_F64 F64 Str2F64(U8 *src,U8 **end_ptr=NULL);
public _extern _STR_TO_DATE CDate Str2Date(U8 *src);
#endif
