//Output from compiled HolyC; input-filter tasks emit public key messages.
U0 NativePutS(U8 *text)
{
  I64 ch;
  if(!text || Bt(&Fs->display_flags,DISPLAYf_SILENT)) return;
  if(Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) {
    while(ch=*text++) {
      (*native_output_msg)(MSG_KEY_DOWN,ch,0,0);
      I386TaskBreakPoll;
    }
  } else {
    I386TextWrite(&console_text,text);
    ConsolePresent;
  }
}
U0 NativePutChars(U64 chars)
{
  U8 text[2];
  text[1]=0;
  while(chars) {
    text[0]=chars&255;
    if(text[0]) NativePutS(text);
    chars>>=8;
  }
}
U0 NativePrint(U8 *fmt,...)
{
  U8 *text=StrPrintJoin(NULL,fmt,argc,argv);
  try { NativePutS(text); }
  catch { Free(text); }
  Free(text);
}
