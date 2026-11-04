U0 ProbeExpressionReport(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{
  if(!kind) {
    KernelLog("PARSER DIAGNOSTIC "); KernelLog(message); KernelLog("\n");
    cc->error_cnt++; throw('Compiler',TRUE);
  }
  cc->warning_cnt++;
}
