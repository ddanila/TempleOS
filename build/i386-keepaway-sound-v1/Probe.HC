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

U0 KAExpire(CTask *owner)
{
  Suspend(owner->animate_task);
  game_t_end=tS-0.1;
  Suspend(owner->animate_task,FALSE);
  while(game_t_end)Sleep(1);
  Sleep(1500);
}

U0 KAWatch(CTask *owner)
{
  while(sys_focus_task==owner && !owner->animate_task)Sleep(1);
  if(!owner->animate_task)KAOut("KEEP popup\n");
  while(!owner->animate_task)Sleep(1);
  KAOut("KEEP playing\n");
  KAScoreSetup(owner,FALSE);
  while(!score0 && !score1)Sleep(1);
  if(score0!=2 || score1)KAOut("FAIL KeepAway handoff\n");
  KAScoreSetup(owner,TRUE);
  while(score0==2 && !score1)Sleep(1);
  if(score0!=8 || score1)KAOut("FAIL KeepAway pass\n");
  KAExpire(owner);
  if(best_score0!=8 || best_score1)KAOut("FAIL KeepAway best score\n");
  KAOut("KEEP finished 8-0\n");
  while(!game_t_end)Sleep(1);
  if(score0 || score1)KAOut("FAIL KeepAway restart\n");
  KAExpire(owner);
  if(best_score0!=8 || best_score1)KAOut("FAIL KeepAway lower score replaced best\n");
  KAOut("KEEP preserved 8-0\n");
}

U0 KAProbe()
{
  CTask *watch=Spawn(&KAWatch,Fs,"KeepAway finish observer");
  CTask *old_animate=Fs->animate_task;
  U8 *old_draw=Fs->draw_it;
  CMenu *old_menu=Fs->cur_menu;
  KeepAway;
  Kill(watch);
  if(Fs->animate_task!=old_animate || Fs->draw_it!=old_draw || Fs->cur_menu!=old_menu)
    KAOut("FAIL KeepAway caller state\n");
  if(best_score0!=8 || best_score1)KAOut("FAIL KeepAway final score\n");
  KAOut("KEEP returned\n");
}
