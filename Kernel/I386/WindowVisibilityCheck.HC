//Calls the actual public updater with an isolated, IRQ-protected task ring.
I64 WindowVisibilityCheck(CTask *anchor)
{
  CTask task;
  U16 *area=CAlloc(9604),*bitmap=CAlloc(8196),*saved_z=gr.win_z_buf,*saved_bits=gr.win_uncovered_bitmap;
  CTask *saved_next=anchor->next_task,*saved_last=anchor->last_task;
  I64 flags=GetRFlags,highest=gr.highest_uncovered,left=anchor->win_left,right=anchor->win_right;
  I64 top=anchor->win_top,bottom=anchor->win_bottom,display=anchor->display_flags,z=anchor->win_z_num;
  I64 i,expected,result=6;
  MemSet(&task,0,sizeof(task)); task.addr=&task; task.task_signature=TASK_SIGNATURE_VAL;
  task.next_task=task.last_task=anchor;
  task.win_left=20; task.win_right=39; task.win_top=10; task.win_bottom=19;
  task.display_flags=1<<DISPLAYf_SHOW|1<<DISPLAYf_NO_BORDER;
  area[0]=0x1234; area[4801]=0x5678; bitmap[0]=0xABCD; bitmap[4097]=0xEF01;
  SetRFlags(flags&~0x200);
  gr.win_z_buf=area+1; gr.win_uncovered_bitmap=bitmap+1; gr.highest_uncovered=0;
  anchor->next_task=anchor->last_task=&task;
  anchor->win_left=0; anchor->win_right=79; anchor->win_top=0; anchor->win_bottom=59;
  anchor->display_flags=1<<DISPLAYf_SHOW|1<<DISPLAYf_NO_BORDER;
  WinZBufUpdate;
  for(i=0;i<4800;i++) {
    expected=1; if(20<=i%80<=39 && 10<=i/80<=19) expected=2;
    if(gr.win_z_buf[i]!=expected) result=-1;
  }
  if(anchor->win_z_num!=1 || task.win_z_num!=2 || gr.highest_uncovered!=2 ||
      !Bt(gr.win_uncovered_bitmap,1) || !Bt(gr.win_uncovered_bitmap,2) || Bt(gr.win_uncovered_bitmap,0)) result=-2;
  anchor->display_flags=0; WinZBufUpdate;
  for(i=0;i<4800;i++) {
    expected=0; if(20<=i%80<=39 && 10<=i/80<=19) expected=1;
    if(gr.win_z_buf[i]!=expected) result=-3;
  }
  if(!Bt(gr.win_uncovered_bitmap,0) || !Bt(gr.win_uncovered_bitmap,1) || Bt(gr.win_uncovered_bitmap,2)) result=-3;
  task.display_flags=0; WinZBufUpdate;
  for(i=0;i<4800;i++) if(gr.win_z_buf[i]) result=-4;
  if(gr.highest_uncovered || !Bt(gr.win_uncovered_bitmap,0) || Bt(gr.win_uncovered_bitmap,1)) result=-4;
  task.display_flags=1<<DISPLAYf_SHOW;
  task.win_left=0; task.win_right=1; task.win_top=0; task.win_bottom=1;
  WinZBufUpdate;
  for(i=0;i<4800;i++) {
    expected=0; if(i%80<=2 && i/80<=2) expected=1;
    if(gr.win_z_buf[i]!=expected) result=-5;
  }
  if(area[0]!=0x1234 || area[4801]!=0x5678 || bitmap[0]!=0xABCD || bitmap[4097]!=0xEF01 || GetRFlags&0x200) result=-6;
  anchor->next_task=saved_next; anchor->last_task=saved_last;
  anchor->win_left=left; anchor->win_right=right; anchor->win_top=top; anchor->win_bottom=bottom;
  anchor->display_flags=display; anchor->win_z_num=z;
  gr.win_z_buf=saved_z; gr.win_uncovered_bitmap=saved_bits; gr.highest_uncovered=highest;
  SetRFlags(flags); Free(area); Free(bitmap); return result;
}
