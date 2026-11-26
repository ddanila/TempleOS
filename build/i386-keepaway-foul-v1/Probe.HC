U0 KAOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 KAFoulWatch(CTask *owner)
{
  I64 i;
  while(sys_focus_task==owner && !owner->animate_task)Sleep(1);
  if(!owner->animate_task)KAOut("KEEP popup\n");
  while(!owner->animate_task)Sleep(1);
  Suspend(owner->animate_task);
  for(i=0;i<PER_SIDE_NUM*2;i++) {
    objs[i].x=400+i*24;
    objs[i].y=600;
    objs[i].DxDt=0;
    objs[i].DyDt=0;
    objs[i].has_ball=FALSE;
    objs[i].stolen_t0=tS;
  }
  human->x=200;
  human->y=300;
  human->foul_t0=tS-2;
  objs[1].x=210;
  objs[1].y=300;
  ball->x=400;
  ball->y=180;
  someone_has_ball=FALSE;
  someone_shooting=FALSE;
  MsSet(owner->pix_left+owner->scroll_x+300,owner->pix_top+owner->scroll_y+150);
  Suspend(owner->animate_task,FALSE);
  while(!score1)Sleep(1);
  if(score0 || score1!=1 || foul_t_end<=tS)KAOut("FAIL KeepAway foul\n");
  KAOut("KEEP foul 0-1\n");
}

U0 KAProbe()
{
  CTask *watch=Spawn(&KAFoulWatch,Fs,"KeepAway foul observer");
  KeepAway;
  Kill(watch);
  KAOut("KEEP returned\n");
}
