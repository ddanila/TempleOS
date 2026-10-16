U0 PrintErr(U8 *fmt,...)
{//Print "Err:" and msg in blinking red.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  GetOutOfDollar;
  "%,p %,p %,p %,p " ST_ERR_ST "%s",Caller,Caller(2),Caller(3),Caller(4),buf;
  Free(buf);
}

U0 PrintWarn(U8 *fmt,...)
{//Print "Warn:" and msg in blinking red.
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  GetOutOfDollar;
  "%,p %,p %,p %,p " ST_WARN_ST "%s",Caller,Caller(2),Caller(3),Caller(4),buf;
  Free(buf);
}
