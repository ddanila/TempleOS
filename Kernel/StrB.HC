#include "/Kernel/StringAllocUtilCore.HC"

U0 GetOutOfDollar()
{//If a $$ has been printed, print another $$ to exit mode.
  CDoc *doc;
  if (IsRaw) {
    if (text.raw_flags&RWF_IN_DOLLAR)
      '$$';
  } else {
    if (fp_doc_put && (doc=(*fp_doc_put)(Fs)) && doc->flags&DOCF_IN_DOLLAR)
      '$$';
  }
}

Bool YorN()
{//Wait for user to answer Y or N.
  I64 ch;
  "(y or n)? ";
  while (TRUE) {
    ch=ToUpper(GetChar(,FALSE));
    if (ch=='Y') {
      "$$PT$$YES$$FG$$\n";
      return TRUE;
    } else if (ch=='N') {
      "$$PT$$NO$$FG$$\n";
      return FALSE;
    }
  }
}

I64 PressAKey()
{//Print "Press a key" and wait for non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key.
  "$$BK,1$$PRESS A KEY$$BK,0$$\n";
  return GetChar(,FALSE);
}

Bool AreYouSure()
{//Print "Are you sure" and waits for Y or N.
  "ARE YOU SURE ";
  return YorN;
}

U0 Help()
{//Dbg help or master help index file.
  if (IsDbgMode)
    DbgHelp;
  else
    PopUp("Type(\"::/Doc/HelpIndex.DD\");DocTop;View;");
}

U0 ScanFlags(U8 *_dst_flags,U8 *lst,U8 *src)
{/*More than 64 flags. Flags passed by ref.

Examples:
$LK,"ScanFlags",A="FF:::/Adam/Opt/Utils/Diff.HC,ScanFlags:2"$(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);

I64 flags=0;
ScanFlags(&flags,"R\0L\0Dump\0Scan\0","+Dump-R"); //Sets Bit#2, Clears Bit#0.
*/
  I64 i;
  U8 *buf,*ptr;
  if (src) {
    buf=MAlloc(StrLen(src)+1);
    while (*src) {
      while (*src && *src!='+' && *src!='-')
	src++;
      if (*src=='+') {
	src++;
	if (*src) {
	  ptr=buf;
	  while (*src && *src!='+' && *src!='-' &&
		*src!=CH_SPACE && *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBts(_dst_flags,i);
	  else {
	    Free(buf);
	    throw('ScanFlag');
	  }
	}
      } else if (*src=='-') {
	src++;
	if (*src) {
	  ptr=buf;
	  while (*src && *src!='+' && *src!='-' &&
		*src!=CH_SPACE && *src!=CH_SHIFT_SPACE)
	    *ptr++=*src++;
	  *ptr=0;
	  i=LstMatch(buf,lst);
	  if (i>=0)
	    LBtr(_dst_flags,i);
	  else {
	    Free(buf);
	    throw('ScanFlag');
	  }
	}
      }
    }
    Free(buf);
  }
}

U8 *StrPrintFlags(U8 *dst,U8 *lst,I64 flags)
{//Only 64 flags. Flags passed by value.
  I64 i;
  *dst=0;
  while (flags) {
    i=Bsf(flags);
    Btr(&flags,i);
    CatPrint(dst,"+%z",i,lst);
  }
  return dst;
}
