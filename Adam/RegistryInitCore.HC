U0 RegInit()
{
  U8 buf[STR_LEN];
  Bool version_present;
  RegDft("Adam/SysMsgFlags","sys_msg_flags[0]=0;\n",TRUE);
  StrPrint(buf,"registry_version=%4.3f;\n",sys_os_version);
  version_present=RegDft("Adam/SysRegVer",buf,TRUE);
  RegExe("Adam");
  if (registry_version!=sys_os_version) {
    RegWrite("Adam/SysRegVer",buf);
    RegExe("Adam");
  }
}
