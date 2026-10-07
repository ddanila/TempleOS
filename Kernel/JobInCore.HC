#ifndef I386_IN_TEXT_SUBMIT
U0 InTextSubmit(U8 *st)
{
  InStr("\"%%s\",%d;Free(%d);",st,st);
}
#endif

U0 In(U8 *fmt,...)
{//Send text to own input buffer. See $LK,"::/Demo/AcctExample/TOS/TOSDistro.HC"$.
  U8 *buf=NULL,*st=NULL;
  try {
    buf=StrPrintJoin(NULL,fmt,argc,argv);
    st=AStrNew(buf);
    InTextSubmit(st);
    st=NULL; //Successful submission transfers ownership to the print/free job.
  }
  catch { Free(st); Free(buf); }
  Free(buf);
}

