I64 ExePrint(U8 *fmt,...)
{//JIT Compile and execute text from a printf().
  I64 res;
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  try {res=ExePutS(buf);}
  catch {Free(buf);} //Preserve propagation while releasing the formatted source.
  Free(buf);
  return res;
}
