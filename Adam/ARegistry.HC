#help_index "Registry"
#include "/Adam/RegistryCore.HC"

#include "/Adam/RegistryPopupCore.HC"

#include "/Adam/RegistryInitCore.HC"

#help_index "Boot/Once;Registry/Once"
#help_file "::/Doc/Once"

public U0 AOnceFlush()
{//Flush AOnce() buf.
  RegWrite("Once/Adam","");
}

public U0 OnceFlush()
{//Flush Once() buf.
  RegWrite("Once/User","");
}

public U0 AOnce(U8 *fmt,...)
{//Add Adam code to $LK,"~/Registry.HC"$, executed next boot.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  if (!Bt(&sys_run_level,RLf_ONCE_ADAM))
    AOnceFlush;
  RegAppend("Once/Adam","%s\n",buf);
  Free(buf);
}

public U0 Once(U8 *fmt,...)
{//Add User code to $LK,"~/Registry.HC"$, executed next boot.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  if (!Bt(&sys_run_level,RLf_ONCE_USER))
    OnceFlush;
  RegAppend("Once/User","%s\n",buf);
  Free(buf);
}

public U0 AOnceDrv(U8 drv_let=0,U8 *fmt,...)
{//Add Adam code to drv $LK,"~/Registry.HC"$, executed next boot.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  I64 old_drv_let=*sys_registry_doc->filename.name;
  if (drv_let)
    *sys_registry_doc->filename.name=drv_let;
  if (!Bt(&sys_run_level,RLf_ONCE_ADAM))
    AOnceFlush;
  RegAppend("Once/Adam","%s\n",buf);
  Free(buf);
  *sys_registry_doc->filename.name=old_drv_let;
}

public U0 OnceDrv(U8 drv_let=0,U8 *fmt,...)
{//Add User code to drv $LK,"~/Registry.HC"$, executed next boot.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  I64 old_drv_let=*sys_registry_doc->filename.name;
  if (drv_let)
    *sys_registry_doc->filename.name=drv_let;
  if (!Bt(&sys_run_level,RLf_ONCE_USER))
    OnceFlush;
  RegAppend("Once/User","%s\n",buf);
  Free(buf);
  *sys_registry_doc->filename.name=old_drv_let;
}

public U0 OnceExe()
{//Execute Once code. Call goes in $LK,"~/Once.HC"$.
  try {

    RegDft("Once/Adam","");
    if (RegCnt("Once/Adam")>2) {
      Adam("RegExe(\"Once/Adam\");");
      AOnceFlush;
    }
    LBts(&sys_run_level,RLf_ONCE_ADAM);

    RegDft("Once/User","");
    if (RegCnt("Once/User")>2) {
      RegExe("Once/User");
      OnceFlush;
    }
    LBts(&sys_run_level,RLf_ONCE_USER);

  } catch {
    AOnceFlush;
    LBts(&sys_run_level,RLf_ONCE_ADAM);
    OnceFlush;
    LBts(&sys_run_level,RLf_ONCE_USER);
  }
}
