#ifndef KEY_GET_LOCAL
#define KEY_GET_LOCAL
#endif
#ifndef KEY_GET_PHASE
#define KEY_GET_PHASE (ToI64(GetTSC*5/cnts.time_stamp_freq)&1)
#endif
#ifndef KEY_GET_CURSOR
#define KEY_GET_CURSOR PutChars
#endif
#ifndef KEY_GET_DEBUG
#define KEY_GET_DEBUG IsDbgMode
#endif
#ifndef KEY_GET_WAIT
#define KEY_GET_WAIT Yield
#endif
#ifndef KEY_GET_DEBUG_POLL
#define KEY_GET_DEBUG_POLL KeyGetDebugPoll
#endif
I64 GetKey(I64 *_scan_code=NULL,Bool echo=FALSE,Bool raw_cursor=FALSE)
{//Waits for $LK,"MSG_KEY_DOWN",A="MN:MSG_KEY_DOWN"$ message and returns $LK,"ASCII",A="MN:CH_CTRLA"$.
//Sets $LK,"scan_code",A="FI:::/Doc/CharOverview.DD"$.
  //$LK,"ScanKey",A="MN:ScanKey"$() throws away other message types.
  I64 ch,sc;
  Bool cursor_on=FALSE;
  KEY_GET_LOCAL;
  while (!ScanKey(&ch,&sc,FALSE)) {
    if (IsRaw && raw_cursor) {
      if (!cursor_on && KEY_GET_PHASE) {
	KEY_GET_CURSOR(0xDB);
	cursor_on=TRUE;
      } else if (cursor_on && !(KEY_GET_PHASE)) {
	KEY_GET_CURSOR(CH_BACKSPACE);
	cursor_on=FALSE;
      }
    }
    LBts(&Fs->task_flags,TASKf_IDLE);
    if (KEY_GET_DEBUG) {
//We don't want interrupt-driven keyboard when in debugger
      //because that could have side-effects or crash, so we poll
      //keyboard when in debugger with interrupts off.
      KEY_GET_DEBUG_POLL;
    } else {
      LBts(&Fs->task_flags,TASKf_AWAITING_MSG);
      KEY_GET_WAIT;
    }
    LBtr(&Fs->task_flags,TASKf_IDLE);
  }
  if (IsRaw && raw_cursor && cursor_on)
    KEY_GET_CURSOR(CH_BACKSPACE);
  if (echo)
    PutKey(ch,sc);
  if (_scan_code) *_scan_code=sc;
  return ch;
}
