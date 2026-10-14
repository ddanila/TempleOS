Bool ScanKey(I64 *_ch=NULL,I64 *_scan_code=NULL,Bool echo=FALSE)
{//Checks for $LK,"MSG_KEY_DOWN",A="MN:MSG_KEY_DOWN"$ and returns FALSE immediately if no key.
//Sets $LK,"ASCII",A="MN:CH_CTRLA"$ and $LK,"scan_code",A="FI:::/Doc/CharOverview.DD"$.
  //Removes key message and returns TRUE.
  //$LK,"ScanMsg",A="MN:ScanMsg"$() throws away other message types.
  I64 ch=0,sc=0;
  if (ScanMsg(&ch,&sc,1<<MSG_KEY_DOWN)) {
    if (_ch) *_ch=ch;
    if (_scan_code) *_scan_code=sc;
    if (echo)
      PutKey(ch,sc);
    return TRUE;
  } else {
    if (_ch) *_ch=0;
    if (_scan_code) *_scan_code=0;
    return FALSE;
  }
}
