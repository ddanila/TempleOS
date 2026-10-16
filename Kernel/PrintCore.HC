U0 Print(U8 *fmt,...)
{//$LK,"Print(\"\") Fmt Strings",A="FI:::/Doc/Print.DD"$.  See $LK,"StrPrintJoin",A="MN:StrPrintJoin"$().
//Don't use this.  $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  PutS(buf);//Don't use PutS().  $LK,"See Print() shortcut.",A="FF:::/Doc/HolyC.DD,DemoHolyC"$
  Free(buf);
}

