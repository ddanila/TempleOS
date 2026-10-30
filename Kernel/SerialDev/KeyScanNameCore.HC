//Original formatted scan-code names.
U8 *ScanCode2KeyName(I64 sc)
{//Scan code to key name.
  I64 ch;
  U8 buf[STR_LEN],*st;
  *buf=0;
  if (sc&SCF_CTRL)
    CatPrint(buf,"CTRL ");
  if (sc&SCF_ALT)
    CatPrint(buf,"ALT ");
  if (sc&SCF_SHIFT)
    CatPrint(buf,"SHIFT ");
  if (sc&SCF_NO_SHIFT)
    CatPrint(buf,"      ");
  if (ch=ScanCode2Char(sc&255)) {
    st=Char2KeyName(ch,FALSE);
    StrCpy(buf+StrLen(buf),st);
    Free(st);
  } else {
    switch (sc&255) {
      case SC_BACKSPACE:CatPrint(buf,"BACK");	break;
      case SC_CAPS:	CatPrint(buf,"CAPS");	break;
      case SC_NUM:	CatPrint(buf,"NUM");	break;
      case SC_SCROLL:	CatPrint(buf,"SCROLL");	break;
      case SC_CURSOR_UP:CatPrint(buf,"UP");	break;
      case SC_CURSOR_DOWN:CatPrint(buf,"DOWN");	break;
      case SC_CURSOR_LEFT:CatPrint(buf,"LEFT");	break;
      case SC_CURSOR_RIGHT:CatPrint(buf,"RIGHT"); break;
      case SC_PAGE_UP:	CatPrint(buf,"PAGE_UP");  break;
      case SC_PAGE_DOWN:CatPrint(buf,"PAGE_DOWN");break;
      case SC_HOME:	CatPrint(buf,"HOME");	break;
      case SC_END:	CatPrint(buf,"END");	break;
      case SC_INS:	CatPrint(buf,"INS");	break;
      case SC_DELETE:	CatPrint(buf,"DELETE");	break;
      case SC_F1:	CatPrint(buf,"F1");	break;
      case SC_F2:	CatPrint(buf,"F2");	break;
      case SC_F3:	CatPrint(buf,"F3");	break;
      case SC_F4:	CatPrint(buf,"F4");	break;
      case SC_F5:	CatPrint(buf,"F5");	break;
      case SC_F6:	CatPrint(buf,"F6");	break;
      case SC_F7:	CatPrint(buf,"F7");	break;
      case SC_F8:	CatPrint(buf,"F8");	break;
      case SC_F9:	CatPrint(buf,"F9");	break;
      case SC_F10:	CatPrint(buf,"F10");	break;
      case SC_F11:	CatPrint(buf,"F11");	break;
      case SC_F12:	CatPrint(buf,"F12");	break;
      case SC_GUI:	CatPrint(buf,"WINDOWS");  break;
      case SC_PRTSCRN1:	CatPrint(buf,"PRTSCRN1"); break;
      case SC_PRTSCRN2:	CatPrint(buf,"PRTSCRN2"); break;
    }
  }
  return StrNew(buf);
}

