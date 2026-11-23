U0 KAOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 KAScoreSetup(CTask *owner,Bool recent_pass)
{
  I64 i;
  Suspend(owner->animate_task);
  for(i=0;i<PER_SIDE_NUM*2;i++) {
    objs[i].has_ball=FALSE;
    objs[i].stolen_t0=tS;
  }
  human->stolen_t0=0;
  ball->x=human->x;
  ball->y=human->y;
  ball->z=ball->radius;
  ball->DxDt=0;
  ball->DyDt=0;
  ball->DzDt=0;
  someone_shooting=FALSE;
  someone_has_ball=FALSE;
  last_owner=NULL;
  if(recent_pass)
    shot_land_t=tS+1.0;
  else
    shot_land_t=0;
  Suspend(owner->animate_task,FALSE);
}

U0 KAWatch(CTask *owner)
{
  F64 starting_end;
  while(sys_focus_task==owner && !owner->animate_task)Sleep(1);
  if(!owner->animate_task)KAOut("KEEP popup\n");
  while(!owner->animate_task)Sleep(1);
  starting_end=game_t_end;
  if(!human || !ball || !owner->draw_it || !starting_end)
    KAOut("FAIL KeepAway initial state\n");
  KAOut("KEEP playing\n");
  while(human->DzDt<=0)Sleep(1);
  KAOut("KEEP jumped\n");
  while(game_t_end<=starting_end)Sleep(1);
  if(score0 || score1)KAOut("FAIL KeepAway restart score\n");
  KAOut("KEEP restarted\n");
  KAScoreSetup(owner,FALSE);
  while(!score0 && !score1)Sleep(1);
  if(score0!=2 || score1 || last_owner!=human)
    KAOut("FAIL KeepAway hand-off scoring\n");
  KAOut("KEEP handoff score 2\n");
  KAScoreSetup(owner,TRUE);
  while(score0==2 && !score1)Sleep(1);
  if(score0!=8 || score1 || last_owner!=human)
    KAOut("FAIL KeepAway pass scoring\n");
  KAOut("KEEP pass score 8\n");
  while(!someone_shooting)Sleep(1);
  KAOut("KEEP shot started\n");

}

U0 KAProbe()
{
  CTask *watch=Spawn(&KAWatch,Fs,"KeepAway test observer");
  CTask *old_animate=Fs->animate_task;
  U8 *old_draw=Fs->draw_it;
  CMenu *old_menu=Fs->cur_menu;
  KeepAway;
  Kill(watch);
  if(Fs->animate_task!=old_animate || Fs->draw_it!=old_draw || Fs->cur_menu!=old_menu)
    KAOut("FAIL KeepAway caller state\n");
  KAOut("KEEP returned\n");
}
