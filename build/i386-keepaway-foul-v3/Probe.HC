U0 KAOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 KAFoulWatch(CTask *owner)
{
  I64 i,mouse_x,mouse_y,direction;
  U8 *line;
  while(sys_focus_task==owner && !owner->animate_task)Sleep(1);
  if(!owner->animate_task)KAOut("KEEP popup\n");
  while(!owner->animate_task)Sleep(1);
  Suspend(owner->animate_task);
  line=MStrPrint("KEEP foul baseline %d-%d\n",score0,score1);
  KAOut(line);Free(line);
  for(i=0;i<PER_SIDE_NUM*2;i++) {
    objs[i].x=400+i*24;
    objs[i].y=600;
    objs[i].DxDt=0;
    objs[i].DyDt=0;
    objs[i].has_ball=FALSE;
    objs[i].stolen_t0=tS+20;
  }
  mouse_x=ms.pos.x-owner->pix_left-owner->scroll_x;
  mouse_y=(ms.pos.y-owner->pix_top-owner->scroll_y)*2;
  direction=1;
  if(mouse_x<320)direction=-1;
  human->x=mouse_x-direction*100;
  human->y=ClampI64(mouse_y,80,owner->pix_height*2-80);
  human->foul_t0=tS-2;
  objs[1].x=human->x+10*direction;
  objs[1].y=human->y;
  line=MStrPrint("KEEP foul pointer %d,%d direction=%d\n",mouse_x,mouse_y,direction);
  KAOut(line);Free(line);
  ball->x=400;
  ball->y=180;
  someone_has_ball=FALSE;
  someone_shooting=FALSE;
  score0=score1=0;
  foul_t_end=0;
  Suspend(owner->animate_task,FALSE);
  while(!score1)Sleep(1);
  line=MStrPrint("KEEP foul observed %d-%d active=%d\n",score0,score1,foul_t_end>tS);
  KAOut(line);Free(line);
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
