#ifndef POPUP_PRINT_FUNCTION
#define POPUP_PRINT_FUNCTION PopUpPrint
#define POPUP_PRINT_RUN PopUp
#endif
#ifndef POPUP_PRINT_SCOPE_LOCAL
#define POPUP_PRINT_SCOPE_LOCAL
#define POPUP_PRINT_SCOPE_OPEN
#define POPUP_PRINT_SCOPE_CLOSE
#endif
I64 POPUP_PRINT_FUNCTION(U8 *fmt,...)
{//Execute variadically formatted code in a real popup servant.
  U8 *buf=NULL;
  I64 res;
  POPUP_PRINT_SCOPE_LOCAL;
  try {
    POPUP_PRINT_SCOPE_OPEN;
    buf=StrPrintJoin(NULL,fmt,argc,argv);
    res=POPUP_PRINT_RUN(buf,Fs);
  } catch { POPUP_PRINT_SCOPE_CLOSE;Free(buf); }
  POPUP_PRINT_SCOPE_CLOSE;
  Free(buf);
  return res;
}
