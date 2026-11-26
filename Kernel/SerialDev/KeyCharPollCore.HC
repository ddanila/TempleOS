public I64 ScanChar()
{//Checks for $LK,"MSG_KEY_DOWN",A="MN:MSG_KEY_DOWN"$ and returns 0 immediately if no key.
//Waits for $LK,"MSG_KEY_UP",A="MN:MSG_KEY_UP"$ of non-zero $LK,"ASCII",A="MN:CH_CTRLA"$ key and returns $LK,"ASCII",A="MN:CH_CTRLA"$ if key.
  //$LK,"ScanMsg",A="MN:ScanMsg"$() throws away other message types.
  I64 arg1a,arg2a,arg1b,arg2b;
  if (!ScanMsg(&arg1a,&arg2a,1<<MSG_KEY_DOWN)||!arg1a)
    return 0;
  else
    do GetMsg(&arg1b,&arg2b,1<<MSG_KEY_UP);
    while (!arg1b);  //Be careful of $LK,"SC_SHIFT",A="MN:SC_SHIFT"$ and $LK,"SC_CTRL",A="MN:SC_CTRL"$, etc.
  return arg1a;
}

