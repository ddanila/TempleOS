U0 KeyDescSet(U8 *fmt,...)
{//Call this from key hndlr to report desc in $LK,"KeyMap",A="MN:KeyMap"$().
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  StrCpy(keydev.desc,buf);
  keydev.hndlr=Caller;
  Free(buf);
}

