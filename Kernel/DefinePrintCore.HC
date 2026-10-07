U0 DefinePrint(U8 *dname,U8 *src,...)
{//Create DEFINE entry with $LK,"Print",A="FI:::/Doc/Print.DD"$()ed string.
  U8 *buf=StrPrintJoin(NULL,src,argc,argv);
  DefineLoad(dname,buf);
  Free(buf);
}
