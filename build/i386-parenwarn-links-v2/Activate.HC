U0 ParenWarnLinkCheck()
{
  CDoc *warnings=DocRead("C:/Probe/ParenWarnings.DD");
  CDoc *put=DocPut,*display=DocDisplay,*border=DocBorder;
  CDocEntry *entry=warnings->head.next;
  I64 action=0,result;

  while(entry!=warnings && (entry->type_u8!=DOCT_LINK || !entry->aux_str ||
      StrCmp(entry->aux_str,"FL:C:/Demo/ParenWarn.HC,9")))
    entry=entry->next;
  if(entry==warnings)throw('NoLink',TRUE);

  warnings->cmd_U8=CH_SPACE;
  FlushMsgs;
  Msg(MSG_KEY_DOWN,'Z',0);
  Msg(MSG_KEY_DOWN,CH_ESC,0);
  result=DocEntryRun(warnings,entry,TRUE,&action);
  if(!result || !action || Bt(&warnings->locked_flags,DOClf_LOCKED) ||
      DocPut!=put || DocDisplay!=display || DocBorder!=border)
    throw('WarnLnk',TRUE);
  FlushMsgs;
  DocDel(warnings);
}
