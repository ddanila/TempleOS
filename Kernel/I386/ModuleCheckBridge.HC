//The boot kernel retains the complete validator before any provider is loaded.
//Keep provider-local entry points so publication bounds remain enforceable.
#include "/Kernel/I386/ModuleCheck.HH"
import Bool I386KernelModuleValid(U8 *data,I64 size);
import Bool I386KernelModuleValidParts(CI386ModuleHeader *header,CI386ModuleRecord *records,
  U8 *strings,I64 size,U8 (*code)(U8 *context,U32 offset),U8 *context);
public Bool I386ModuleValid(U8 *data,I64 size)
{
  return I386KernelModuleValid(data,size);
}
public Bool I386ModuleValidParts(CI386ModuleHeader *header,CI386ModuleRecord *records,
  U8 *strings,I64 size,U8 (*code)(U8 *context,U32 offset),U8 *context)
{
  return I386KernelModuleValidParts(header,records,strings,size,code,context);
}
