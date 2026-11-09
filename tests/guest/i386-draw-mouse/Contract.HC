U8 dm_pixels[12*1024];I64 dm_values[12*8];
I64 dm_calls,dm_grabs,dm_x,dm_y,dm_closed;
U0 DMLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 DMCustom(CDC *dc,I64 x,I64 y)
{
  dm_calls++;dm_x=x;dm_y=y;dc->color=GREEN;GrRect(dc,x,y,3,2);
}
U0 DMGrab(CDC *dc,I64 x,I64 y,Bool closed)
{
  dm_grabs++;dm_x=x;dm_y=y;dm_closed=closed;
  dc->color=RED;GrRect(dc,x,y,closed+2,3);
}
U0 DMProbe()
{
  CMsStateGlbls old_ms;
  U0 (*old_draw)(CDC *dc,I64 x,I64 y);
  U0 (*old_grab)(CDC *dc,I64 x,I64 y,Bool closed);
  Bool old_scroll=winmgr.grab_scroll,old_closed=winmgr.grab_scroll_closed;
  Bool suspended=Suspend(sys_winmgr_task);
  CDC *dc=NULL;
  I64 i,*v;
  U8 *s;
  old_draw=gr.fp_draw_ms;old_grab=gr.fp_draw_grab_ms;
  MemCpy(&old_ms,&ms,sizeof(CMsStateGlbls));
  try {
    dc=DCNew(32,32);
    for(i=0;i<12;i++) {
      DCFill(dc,WHITE);dc->flags=0;dc->thick=5;dc->color=BLUE;
      dm_calls=dm_grabs=dm_x=dm_y=dm_closed=0;
      ms.show=TRUE;ms.pos.x=12;ms.pos.y=12;ms.lb=ms.rb=FALSE;
      gr.fp_draw_ms=&DrawStdMs;gr.fp_draw_grab_ms=NULL;
      winmgr.grab_scroll=winmgr.grab_scroll_closed=FALSE;
      switch(i) {
        case 0:
          dc->flags=DCF_TRANSFORMATION|DCF_SYMMETRY;
          DrawStdMs(dc,12,12);break;
        case 1:
          dc->thick=2;dc->color=LTCYAN;DrawWaitMs(dc,16,16);break;
        default:
          if(i==3||i==5)ms.lb=TRUE;
          if(i==4||i==5)ms.rb=TRUE;
          if(i==6)ms.show=FALSE;
          if(i==7)gr.fp_draw_ms=NULL;
          if(i==8)gr.fp_draw_ms=&DMCustom;
          if(i==9||i==10) {
            winmgr.grab_scroll=TRUE;winmgr.grab_scroll_closed=i==10;
            gr.fp_draw_grab_ms=&DMGrab;
          }
          if(i==11)winmgr.grab_scroll=TRUE;
          DrawMs(dc);
      }
      MemCpy(dm_pixels+i*1024,dc->body,1024);
      v=dm_values+i*8;
      v[0]=dc->thick;v[1]=dc->color;v[2]=dc->flags;v[3]=dm_calls;
      v[4]=dm_grabs;v[5]=dm_x;v[6]=dm_y;v[7]=dm_closed;
    }
    DCDel(dc);dc=NULL;
  } catch {
    DCDel(dc);gr.fp_draw_ms=old_draw;gr.fp_draw_grab_ms=old_grab;
    winmgr.grab_scroll=old_scroll;winmgr.grab_scroll_closed=old_closed;
    MemCpy(&ms,&old_ms,sizeof(CMsStateGlbls));Suspend(sys_winmgr_task,suspended);
  }
  gr.fp_draw_ms=old_draw;gr.fp_draw_grab_ms=old_grab;
  winmgr.grab_scroll=old_scroll;winmgr.grab_scroll_closed=old_closed;
  MemCpy(&ms,&old_ms,sizeof(CMsStateGlbls));Suspend(sys_winmgr_task,suspended);
  s=MStrPrint("EXPORT draw-mouse-pixels.bin %X %X\n",dm_pixels,sizeof(dm_pixels));DMLog(s);Free(s);
  s=MStrPrint("EXPORT draw-mouse-values.bin %X %X\n",dm_values,sizeof(dm_values));DMLog(s);Free(s);
  DMLog("DRAW MOUSE DONE\n");
}
