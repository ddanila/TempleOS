#help_index "DolDoc"

#include "/Adam/DolDoc/DocGetKeyCore.HC"

#help_index "DolDoc/Input;StdIn/DolDoc"
#include "::/Adam/DolDoc/DocScanLineCore.HC"

#include "/Adam/DolDoc/DocGetStrCore.HC"

#help_index "Keyboard Devices;Char/Input;StdIn"
public I64 GetI64(U8 *msg=NULL,I64 dft=0,I64 lo=I64_MIN,I64 hi=I64_MAX)
{//Prompt user for I64 expression.
  Bool okay;
  U8 *st;
  I64 res;
  while (TRUE) {
    if (msg)
      "" msg,dft;
    st=GetStr;
    if (!*st) {
      Free(st);
      return dft;
    }
    try {
      res=ExePrint2("ToI64(%s);",st);
      okay=TRUE;
    } catch {
      Fs->catch_except=TRUE;
      okay=FALSE;
    }
    Free(st);
    if (okay && lo<=res<=hi)
      return res;
  }
}

public F64 GetF64(U8 *msg=NULL,F64 dft=0,F64 lo=F64_MIN,F64 hi=F64_MAX)
{//Prompt user for F64 expression.
  Bool okay;
  U8 *st;
  F64 res;
  while (TRUE) {
    if (msg)
      "" msg,dft;
    st=GetStr;
    if (!*st) {
      Free(st);
      return dft;
    }
    try {
      res=ExePrint2("ToF64(%s);",st)(F64);
      okay=TRUE;
    } catch {
      Fs->catch_except=TRUE;
      okay=FALSE;
    }
    Free(st);
    if (okay && lo<=res<=hi)
      return res;
  }
}

public CDate GetDate(U8 *msg=NULL,CDate dft=I64_MIN,
	CDate lo=I64_MIN,CDate hi=I64_MAX)
{//Prompt user for date expression. (Use $LK,"Now",A="MN:Now"$() if you want current time.)
  U8 *st;
  CDate res;
  if (dft==I64_MIN) dft=Now;
  while (TRUE) {
    if (msg)
      "" msg,dft,dft;
    st=GetStr;
    if (!*st) {
      Free(st);
      return dft;
    }
    res=Str2Date(st);
    Free(st);
    if (res>=lo && res<=hi)
      return res;
  }
}
