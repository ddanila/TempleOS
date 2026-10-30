#ifndef I386_PUBLIC_FORMAT_INCLUDED
#define I386_PUBLIC_FORMAT_INCLUDED
public _extern _STRMATCH U8 *StrMatch(U8 *needle,U8 *haystack);
public _extern _STRNCMP I64 StrNCmp(U8 *left,U8 *right,I64 n);
public _extern _STRICMP I64 StrICmp(U8 *st1,U8 *st2);
public _extern _STRNICMP I64 StrNICmp(U8 *st1,U8 *st2,I64 n);
#include "/Kernel/I386/PublicKeyDev.HH"
#include "/Kernel/StringFindFlags.HH"
public _extern _STR_FIND U8 *StrFind(U8 *needle,U8 *haystack_str,I64 flags=0);
public _extern _STR_PRINT_JOIN U8 *StrPrintJoin(U8 *dst,U8 *fmt,I64 argc,I64 *argv);
public _extern _STR_PRINT U8 *StrPrint(U8 *dst,U8 *fmt,...);
public _extern _CAT_PRINT U8 *CatPrint(U8 *dst,U8 *fmt,...);
public _extern _MSTR_PRINT U8 *MStrPrint(U8 *fmt,...);
public _extern _PRINT U0 Print(U8 *fmt,...);
#include "/Kernel/DiagnosticText.HH"
public _extern _GET_OUT_OF_DOLLAR U0 GetOutOfDollar();
public _extern _PRINT_ERR U0 PrintErr(U8 *fmt,...);
public _extern _PRINT_WARN U0 PrintWarn(U8 *fmt,...);
public _extern _PUT_S U0 PutS(U8 *text);
public _extern _PUT_CHARS U0 PutChars(U64 chars);
public _extern _STR_SCAN U8 *StrScan(U8 *src,U8 *fmt,...);
public _extern _STR_TO_I64 I64 Str2I64(U8 *src,I64 radix=10,U8 **end_ptr=NULL);
public _extern _STR_TO_F64 F64 Str2F64(U8 *src,U8 **end_ptr=NULL);
public _extern _STR_TO_DATE CDate Str2Date(U8 *src);
#include "/Kernel/StringUtilFlags.HH"
public _extern _STR_OCC I64 StrOcc(U8 *src,I64 ch);
public _extern _STR_FIRST_OCC U8 *StrFirstOcc(U8 *src,U8 *marker);
public _extern _STR_LAST_OCC U8 *StrLastOcc(U8 *src,U8 *marker);
public _extern _STR_FIRST_REM U8 *StrFirstRem(U8 *src,U8 *marker,U8 *dst=NULL);
public _extern _STR_LAST_REM U8 *StrLastRem(U8 *src,U8 *marker,U8 *dst=NULL);
public _extern _STR_UTIL U8 *StrUtil(U8 *src,I64 flags);
public _extern _MSTR_UTIL U8 *MStrUtil(U8 *src,I64 flags,F64 indent_scale_factor=0);
#endif
