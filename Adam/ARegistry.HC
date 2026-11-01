#help_index "Registry"
#include "/Adam/RegistryCore.HC"

public Bool OneTimePopUp(U8 *_flags,I64 flag_num,U8 *msg)
{//See $LK,"::/Apps/X-Caliber/X-Caliber.HC"$.
  Bool res=FALSE;
  CDoc *doc=DocNew;
  CDocEntry *doc_e;
  if (!Bt(_flags,flag_num)) {
    if (msg) DocPrint(doc,"%s",msg);
    doc_e=DocPrint(doc,"\n$$CB,\"Do not show this msg again.\",LE=1$$");
    DocPrint(doc,"$$CM+CX,0,4$$$$BT,\"OKAY\",LE=1$$\n");
    if (PopUpMenu(doc)==1 && doc_e->de_flags&DOCEF_CHECKED_COLLAPSED) {
      LBts(_flags,flag_num);
      res=TRUE;
    }
    DocDel(doc);
  }
  return res;
}

U0 RegOneTimePopUp(I64 flag_num,U8 *msg)
{//You're not supposed to make system pop-up flags, only me.
  if (OneTimePopUp(sys_msg_flags,flag_num,msg))
    RegWrite("Adam/SysMsgFlags","sys_msg_flags[0]=0x%X;\n",
	  sys_msg_flags[0]);
}

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
