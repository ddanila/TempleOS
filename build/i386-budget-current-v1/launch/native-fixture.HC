Cd("C:/");DirMk("C:/BudgetProbeHome");HomeSet("C:/BudgetProbeHome");

CDoc *budget_launch_put;
U0 BudgetLaunchLog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}
U0 BudgetLaunchWatch(CTask *owner)
{
  CDoc *doc;
  while (TRUE) {
    doc=owner->put_doc;
    if (doc && doc!=budget_launch_put && doc->user_put_key) {
      BudgetLaunchLog("BUDGET LAUNCH active\n");
      return;
    }
    Sleep(5);
  }
}
U0 BudgetLaunch()
{
  CDoc *display=Fs->display_doc;
  CTaskSettings *settings=Fs->next_settings;
  I64 size;
  U8 *accounts,*data,*strings;
  budget_launch_put=Fs->put_doc;
  Spawn(&BudgetLaunchWatch,Fs,"Budget observer");
  ExeFile("::/Apps/Budget/Run.HC");
  if (Fs->put_doc!=budget_launch_put || Fs->display_doc!=display ||
      Fs->next_settings!=settings)
    throw('BgtLaunch',TRUE);
  accounts=FileRead("~/Budget/Accts.DD.Z",&size);
  data=FileRead("~/Budget/Bgt.DATA.Z");
  strings=FileRead("~/Budget/Strs.DD.Z");
  if (!accounts || !size || !StrMatch("BANK",accounts) || data || strings)
    throw('BgtLaunch',TRUE);
  Free(accounts);
  BudgetLaunchLog("BUDGET LAUNCH done\n");
}
BudgetLaunch;
