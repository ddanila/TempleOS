#include "/Kernel/I386/ExceptNative.HH"
import U0 i386_except_invoke(CI386ExceptCapture *capture);
import U0 i386_except_resume(CI386ExceptCapture *capture);
public Bool I386ExceptInstallNative(U0 (*report)(CI386Task *task,I64 ch),
  U0 (*fatal)(CI386Task *task,I64 status,I64 ch))
{
  CI386ExceptServices services;
  services.invoke=&i386_except_invoke;
  services.resume=&i386_except_resume;
  services.report=report; services.fatal=fatal;
  return I386ExceptInstall(&services);
}
