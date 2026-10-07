#ifndef I386_MODULE_CHECK_INCLUDED
#define I386_MODULE_CHECK_INCLUDED
#include "/Kernel/I386/Module.HH"
public extern Bool I386ModuleValid(U8 *data,I64 size);
public extern Bool I386ModuleValidParts(CI386ModuleHeader *header,CI386ModuleRecord *records,
  U8 *strings,I64 size,U8 (*code)(U8 *context,U32 offset),U8 *context);
#endif
