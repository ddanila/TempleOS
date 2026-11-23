I64 xc_pointer[2];

U0 XCLog(U8 *message)
{
  while (*message) OutU8(0xE9,*message++);
}

U0 XCWatch(CTask *owner)
{
  Bool level_seen=FALSE,started=FALSE,shot=FALSE;
  F64 reload;
  U8 line[128];
  StrPrint(line,"XC pointer %X\n",xc_pointer);
  XCLog(line);
  while (TRUE) {
    xc_pointer[0]=ms.pos.x;
    xc_pointer[1]=ms.pos.y;
    if (owner->draw_it==&DrawIt && human) {
      if (!level_seen && show_level_msg && remaining>0) {
        StrPrint(line,"XC level %d enemies %d score %d\n",level,remaining,score);
        XCLog(line);
        level_seen=TRUE;
      }
      if (level_seen && !started && !show_level_msg) {
        reload=human->reload_timeout;
        XCLog("XC running\n");
        started=TRUE;
      }
      if (started && !shot && human->reload_timeout>reload) {
        XCLog("XC gun fired\n");
        shot=TRUE;
      }
    }
    Sleep(1);
  }
}

U0 XCProbe()
{
  CTask *watch=Spawn(&XCWatch,Fs,"X-Caliber observer");
  Seed(12345678);
  XCLog("XC ready\n");
  XCaliber;
  Kill(watch);
  XCLog("XC returned\n");
}
XCProbe;
