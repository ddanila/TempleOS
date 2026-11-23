U0 PALog(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 PAProbe()
{
  CTask *child,*owner=Fs;
  U8 line[160];
  I64 key,scan;
  WinFocus(owner);
  PopUp("U8 *p=\"POPUP view ready\\n\";while(*p)OutU8(0xE9,*p++);"
        "\"Popup focus probe\\n\";View;"
        "p=\"POPUP view returned\\n\";while(*p)OutU8(0xE9,*p++);",NULL,&child);
  StrPrint(line,"POPUP state %X %X %X\n",owner,child,&sys_focus_task);
  PALog(line);
  while(TaskValidate(child))Sleep(1);
  StrPrint(line,"POPUP retired focus=%X\n",sys_focus_task);
  PALog(line);
  do GetMsg(&key,&scan,1<<MSG_KEY_DOWN);
  while(key!='q');
  PALog("POPUP caller key\n");
}
