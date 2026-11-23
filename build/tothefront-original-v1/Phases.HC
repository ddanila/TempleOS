U0 TTFPhaseLog(U8 *message)
{
  while (*message) OutU8(0xE9,*message++);
}

U0 TTFPhaseWatch(CTask *owner)
{
  I64 old_turn=-1,old_phase=-1;
  U8 line[128],label[64],*action;
  while (owner->draw_it!=&DrawIt) Sleep(1);
  while (owner->draw_it==&DrawIt) {
    if (phase<PHASE_MOVE)
      action="Artillery Plot";
    else if (phase<PHASE_DIRECT)
      action="Move";
    else
      action="Fire";
    StrPrint(label,"Player %d %s",cur_player+1,action);
    if (!StrCmp(msg_buf,label) && (turn!=old_turn || phase!=old_phase)) {
      old_turn=turn;
      old_phase=phase;
      StrPrint(line,"TTF phase %d %d %d %d %d\n",turn,phase,cur_player,alive_cnt[0],alive_cnt[1]);
      TTFPhaseLog(line);
    }
    Sleep(1);
  }
}

U0 TTFPhaseProbe()
{
  CTask *watch=Spawn(&TTFPhaseWatch,Fs,"ToTheFront phase observer");
  ToTheFront;
  Kill(watch);
  TTFPhaseLog("TTF phase workflow returned\n");
}
TTFPhaseProbe;
