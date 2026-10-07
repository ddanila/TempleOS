I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(8,8),*screen=DCNew(32,32);
  CTask task;
  U16 *area=CAlloc(9600),*saved_z=gr.win_z_buf;
  I64 mask=0,left,top,right,bottom,x1=-4,y1=4,x2=12,y2=4;
  I64 flags=GetRFlags;
  dc->color=RED;GrPlot1(dc,-1,0);GrPlot1(dc,8,7);GrPlot1(dc,2,3);
  if(GrPeek(dc,-1,0)==-1 && GrPeek(dc,8,7)==-1 && GrPeek(dc,2,3)==RED && GrPeek0(dc,0,0)==BLACK)mask|=1;
  DCDepthBufAlloc(dc);dc->depth_buf[27]=3;dc->db_z=6;
  I32 *depth=dc->depth_buf;dc->color=GREEN;GrPlot(dc,3,3);
  if(dc->depth_buf==depth && depth[27]==3 && GrPeek0(dc,3,3)==GREEN)mask|=2;
  dc->color=BLUE;GrPlot1(dc,3,3);
  Bool ok=GrPeek0(dc,3,3)==GREEN;dc->db_z=2;GrPlot1(dc,3,3);
  if(ok && depth[27]==2 && GrPeek0(dc,3,3)==BLUE)mask|=4;
  ok=GrClamp(dc,&left,&top,&right,&bottom,2,3) && left==-2 && top==-3 && right==9 && bottom==10;
  if(ok && DCClipLine(dc,&x1,&y1,&x2,&y2) && x1==0 && x2==7 && y1==4 && y2==4)mask|=8;
  MemSet(&task,0,sizeof(task));task.pix_left=task.pix_top=8;
  task.pix_right=task.pix_bottom=23;task.scroll_x=2;task.scroll_y=3;
  task.win_z_num=1;task.next_task=&task;screen->win_task=&task;
  screen->flags=DCF_SCRN_BITMAP;screen->color=RED;
  SetRFlags(flags&~0x200);gr.win_z_buf=area;
  GrPlot1(screen,1,1);ok=GrPeek(screen,1,1)==RED && GrPeek0(screen,11,12)==RED;
  area[81]=2;screen->color=GREEN;GrPlot1(screen,1,1);GrPlot1(screen,-4,-4);
  if(ok && GrPeek(screen,1,1)==-1 && GrPeek0(screen,11,12)==RED && GrPeek0(screen,6,7)==BLACK)mask|=16;
  screen->flags|=DCF_ON_TOP;GrPlot1(screen,1,1);ok=GrPeek(screen,1,1)==GREEN;
  screen->flags=DCF_SCRN_BITMAP;task.next_task=sys_winmgr_task;screen->color=BLUE;
  GrPlot1(screen,1,1);
  if(ok && GrPeek(screen,1,1)==BLUE && GrPeek0(screen,11,12)==BLUE)mask|=32;
  gr.win_z_buf=saved_z;SetRFlags(flags);Free(area);
  DCDel(screen);DCDel(dc);return mask;
}
