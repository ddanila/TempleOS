U0 KAOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 KAWatch(CTask *owner)
{
  F64 remaining,start,mid;
  U8 *line;
  while(sys_focus_task==owner && !owner->animate_task)Sleep(1);
  if(!owner->animate_task)KAOut("KEEP popup\n");
  while(!owner->animate_task)Sleep(1);
  start=tS;
  remaining=game_t_end-start;
  if(remaining<179 || remaining>180)KAOut("FAIL KeepAway initial clock\n");
  KAOut("KEEP regulation clock\n");
  mid=game_t_end-90;
  while(tS<mid && game_t_end)Sleep(15);
  if(!game_t_end)KAOut("FAIL KeepAway expired early\n");
  KAOut("KEEP halftime\n");
  while(game_t_end)Sleep(15);
  if(tS-start<179 || tS-start>185)KAOut("FAIL KeepAway match duration\n");
  Sleep(1500);
  line=MStrPrint("KEEP regulation finished %d-%d in %.3f seconds\n",score0,score1,tS-start-1.5);
  KAOut(line);Free(line);
}

U0 KAProbe()
{
  CTask *watch=Spawn(&KAWatch,Fs,"KeepAway regulation observer");
  Seed(1);
  KeepAway;
  Kill(watch);
  KAOut("KEEP returned\n");
}
