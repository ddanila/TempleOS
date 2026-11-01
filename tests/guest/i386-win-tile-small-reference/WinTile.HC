U0 TSHold(U8 *data){while(TRUE)Yield;}
I64 TSCase()
{
  CTask *t,*saved[24],*target,*anchor=sys_winmgr_task;
  I64 inhibit[24],count=0,i,flags=GetRFlags,after,mask=0;
  target=Spawn(&TSHold,NULL,"Tile small",-1,Fs,4096);
  SetRFlags(flags&~512);
  t=anchor;
  do {
    if(count>=24)throw('TileCnt',TRUE);
    saved[count]=t;inhibit[count++]=t->win_inhibit;
    Bts(&t->win_inhibit,WIf_SELF_FOCUS);t=t->last_task;
  } while(t!=anchor);
  Btr(&target->win_inhibit,WIf_SELF_FOCUS);
  Btr(&target->display_flags,DISPLAYf_NO_BORDER);
  SetRFlags(flags);
  WinTileVert;after=GetRFlags;
  if(target->win_left==1&&target->win_right==78&&target->win_top==2&&target->win_bottom==58)mask|=1;
  if(target->win_width==78&&target->win_height==57)mask|=2;
  if(!((after^flags)&512))mask|=4;
  SetRFlags(flags&~512);
  for(i=0;i<count;i++)saved[i]->win_inhibit=inhibit[i];
  SetRFlags(flags);Kill(target);
  if(sys_winmgr_task==anchor)mask|=8;
  return mask;
}
I64 TSCheck(){I64 v=TSCase;if(v!=15)throw('TileFail',TRUE);return v;}
