#ifndef I386_EXCEPT_RUNTIME_INCLUDED
#define I386_EXCEPT_RUNTIME_INCLUDED
#include "/Kernel/I386/Except.HH"
#include "/Kernel/I386/Task.HH"
class CI386ExceptServices
{
  U0 (*invoke)(CI386ExceptCapture *capture);
  U0 (*resume)(CI386ExceptCapture *capture);
  U0 (*report)(CI386Task *task,I64 ch);
  U0 (*fatal)(CI386Task *task,I64 status,I64 ch);
};
public extern Bool I386ExceptInstall(CI386ExceptServices *services);
public import U0 SysTry(U8 *catch_start,U8 *untry_start);
public extern U0 SysUntry();
public extern U0 throw(I64 ch=0,Bool no_log=FALSE);
public extern Bool I386ExceptEnter(CI386ExceptCapture *capture);
public extern U0 I386ExceptRegistrationFailed();
#endif
