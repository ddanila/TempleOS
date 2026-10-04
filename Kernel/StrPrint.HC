#include "/Kernel/StrPrintCore.HC"

U0 Print(U8 *fmt,...)
{//$LK,"Print(\"\") Fmt Strings",A="FI:::/Doc/Print.DD"$.  See $LK,"StrPrintJoin",A="MN:StrPrintJoin"$().
//Don't use this.  $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  PutS(buf);//Don't use PutS().  $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  Free(buf);
}

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
