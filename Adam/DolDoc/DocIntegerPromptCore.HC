public I64 PopUpGetI64(U8 *msg,I64 dft,I64 lo=I64_MIN,I64 hi=I64_MAX)
{//Prompt for I64 text expression in PopUp win task.
  U8 *st=MStrPrint("GetI64(0x%X,0x%X,0x%X,0x%X);",msg,dft,lo,hi);
  I64 res=PopUp(st,Fs);
  Free(st);
  return res;
}

