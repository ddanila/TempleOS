#ifndef I386_EXCEPT_NATIVE_INCLUDED
#define I386_EXCEPT_NATIVE_INCLUDED
#include "/Kernel/I386/ExceptRuntime.HH"
//Link ExceptContext.HC and SysTry.HC with the public exception runtime.
public extern Bool I386ExceptInstallNative(U0 (*report)(CI386Task *task,I64 ch),
  U0 (*fatal)(CI386Task *task,I64 status,I64 ch));
#endif
