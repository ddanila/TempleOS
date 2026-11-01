U0 TWIdle(U8 *data){while(TRUE)Yield;}
I64 TWContract()
{
  CTask *t=Spawn(&TWIdle,NULL,"Task Window",-1,Fs,8192);
  I64 mask=0;U8 *line;
  if(!t)return 0;
  line=MStrPrint("TASK WINDOW %d %d %d %d %d %d %X %X %X %X %X\n",
    t->win_left,t->win_right,t->win_top,t->win_bottom,t->win_width,t->win_height,
    t->win_inhibit,t->display_flags,t->text_attr,t->border_attr,t->title_src);
  Report(line);Free(line);
  if(t->win_left==1&&t->win_right==78&&t->win_top==13&&t->win_bottom==58)mask|=1;
  if(t->win_inhibit==WIG_TASK_DFT)mask|=2;
  if(t->text_attr==WHITE<<4+BLUE&&t->border_src==BDS_CONST&&
     t->border_attr==DrvTextAttrGet(':'))mask|=4;
  if(t->title_src==TTS_TASK_NAME&&!StrCmp(t->task_title,"Task Window"))mask|=8;
  if(!t->display_flags)mask|=16;
  if(Kill(t))mask|=32;
  line=MStrPrint("TASK WINDOW MASK %d\n",mask);Report(line);Free(line);
  return mask;
}
I64 TWCheck(){I64 v=TWContract;if(v!=63)throw('TaskWin',TRUE);return v;}
