//Ordinary console text is stored in the task document before presentation.
//The planar text surface is the incremental projection, not command storage.
U0 NativeConsoleRecord(U8 *text)
{
  CDoc *doc=NativeTerminalDocument;
  I64 flags;
  Bool unlock;
  if(!doc || !text) return;
  unlock=DocLock(doc); flags=doc->flags;
  try {
    doc->flags|=DOCF_PLAIN_TEXT;
    DocPutS(doc,text);
    doc->flags=flags;
  } catch {
    doc->flags=flags;
    if(unlock) DocUnlock(doc);
  }
  if(unlock) DocUnlock(doc);
}
U0 NativeConsoleWrite(U8 *text)
{
  if(!text) return;
  NativeConsoleRecord(text);
  I386TextWrite(&console_text,text);
}
U0 NativeConsolePut(I64 ch)
{
  CDoc *doc=NativeTerminalDocument;
  Bool unlock,bottom,plain;
  if(doc) {
    unlock=DocLock(doc); bottom=doc->cur_entry==doc;
    plain=(doc->flags&DOCF_PLAIN_TEXT)!=0;
    doc->flags|=DOCF_PLAIN_TEXT;
    try {
      //Coalesce append typing instead of allocating one entry per key.
      if(bottom && ch>=32 && IsEditableText(doc->head.last)) {
        doc->cur_entry=doc->head.last; doc->cur_col=doc->head.last->max_col;
      }
      DocPutKey(doc,ch,0);
      if(!plain) doc->flags&=~DOCF_PLAIN_TEXT;
      if(bottom) { doc->cur_entry=doc; doc->cur_col=0; }
    } catch {
      if(!plain) doc->flags&=~DOCF_PLAIN_TEXT;
      if(bottom) { doc->cur_entry=doc; doc->cur_col=0; }
      if(unlock) DocUnlock(doc);
    }
    if(unlock) DocUnlock(doc);
  }
  I386TextPut(&console_text,ch);
}
CDocEntry *NativeConsolePrompt()
{
  CDoc *doc=NativeTerminalDocument;
  CDocEntry *marker;
  if(!doc) throw('DocOwner',TRUE);
  doc->cur_entry=doc; doc->cur_col=0;
  NativeConsoleWrite("> ");
  marker=DocEntryNewBase(doc,DOCT_PMT);
  DocInsEntry(doc,marker);
  return marker;
}

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
    NativeConsoleWrite(text);
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
