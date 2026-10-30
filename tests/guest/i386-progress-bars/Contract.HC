I64 ProgressBarsContract()
{
  CProgress saved[4];CDC *dc=DCNew(640,480);I64 mask=0;
  MemCpy(saved,sys_progresses,sizeof(saved));MemSet(sys_progresses,0,sizeof(saved));
  DCFill(dc,WHITE);DrawProgressBars(dc);
  if(dc->body[170*dc->width_internal+80]==WHITE)mask|=1;
  sys_progresses[0].max=100;sys_progresses[0].val=50;
  DrawProgressBars(dc);
  if(dc->body[170*dc->width_internal+80]==BLACK && dc->body[180*dc->width_internal+100]==LTGREEN &&
     dc->body[180*dc->width_internal+350]==BLACK)mask|=2;
  sys_progresses[3].max=1;sys_progresses[3].val=1;
  DrawProgressBars(dc);
  if(dc->body[290*dc->width_internal+80]==BLACK && dc->body[300*dc->width_internal+100]==LTGREEN)mask|=4;
  MemCpy(sys_progresses,saved,sizeof(saved));DCDel(dc);return mask;
}
