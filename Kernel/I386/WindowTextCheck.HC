//Shared original/native checks of the services used by document layout.
I64 WindowTextCheck()
{
  CTask task;
  CD3I64 scroll;
  U32 *area=CAlloc(4802*4),*saved=gr.text_base;
  I64 flags=GetRFlags,i,x,y,expected,result=10;
  MemSet(&task,0,sizeof(task));
  task.win_left=-2; task.win_right=12;
  task.win_top=3; task.win_bottom=8;
  task.task_flags=1<<TASKf_TASK_LOCK;
  WinDerivedValsUpdate(&task);
  if(task.win_width!=15 || task.win_height!=6 || task.pix_left!=-16 ||
      task.pix_right!=103 || task.pix_width!=120 || task.pix_top!=24 ||
      task.pix_bottom!=71 || task.pix_height!=48 || (GetRFlags&0x200)!=(flags&0x200)) result=-1;
  SetRFlags(flags&~0x200);
  WinDerivedValsUpdate(&task);
  if(GetRFlags&0x200) result=-2;
  task.scroll_x=-17; task.scroll_y=0x100000001; task.scroll_z=-0x100000002;
  WinScrollNull(&task,&scroll);
  if(task.scroll_x || task.scroll_y || task.scroll_z || scroll.x!=-17 ||
      scroll.y!=0x100000001 || scroll.z!=-0x100000002) result=-3;
  WinScrollRestore(&task,&scroll);
  if(task.scroll_x!=-17 || task.scroll_y!=0x100000001 || task.scroll_z!=-0x100000002) result=-4;
  area[0]=0x12345678; area[4801]=0x87654321; gr.text_base=area+1;
  TextRect(-2,2,-3,1,0xABCDEF01);
  for(i=0;i<4800;i++) {
    expected=0; if(i/80<2 && i%80<3) expected=0xABCDEF01;
    if(gr.text_base[i]!=expected) result=-5;
  }
  //Entirely offscreen ranges must never turn a negative clipped width into a fill count.
  TextRect(90,100,0,0,0xBAD); TextRect(-10,-2,0,0,0xBAD);
  TextRect(0,79,61,70,0xBAD); TextRect(0,79,-5,-1,0xBAD);
  TextRect(2,1,0,0,0xBAD); TextRect(0,0,2,1,0xBAD);
  for(i=0;i<4800;i++) {
    expected=0; if(i/80<2 && i%80<3) expected=0xABCDEF01;
    if(gr.text_base[i]!=expected) result=-6;
  }
  TextRect(78,99,58,70,0xDEADBEEF);
  for(i=0;i<4800;i++) {
    expected=0; if(i/80<2 && i%80<3) expected=0xABCDEF01;
    if(i/80>=58 && i%80>=78) expected=0xDEADBEEF;
    if(gr.text_base[i]!=expected) result=-7;
  }
  task.win_left=10; task.win_top=5; task.win_right=20; task.win_bottom=10;
  task.scroll_x=8; task.scroll_y=8; task.scroll_z=0;
  for(i=0;i<2;i++) {
    MemSet(gr.text_base,0,4800*4);
    TextBorder(&task,1,3,1,2,0x1E,i);
    for(y=0;y<60;y++) for(x=0;x<80;x++) {
      expected=0;
      if(x>=12 && x<=14 && (y==6 || y==9)) expected=0x1E00+text.border_chars[2+i];
      if(y>=7 && y<=8 && (x==11 || x==15)) expected=0x1E00+text.border_chars[4+i];
      if(x==11 && y==6) expected=0x1E00+text.border_chars[6+i];
      if(x==15 && y==6) expected=0x1E00+text.border_chars[8+i];
      if(x==11 && y==9) expected=0x1E00+text.border_chars[10+i];
      if(x==15 && y==9) expected=0x1E00+text.border_chars[12+i];
      if(gr.text_base[y*80+x]!=expected) result=-8-i;
    }
  }
  if(area[0]!=0x12345678 || area[4801]!=0x87654321) result=-10;
  gr.text_base=saved; SetRFlags(flags); Free(area);
  return result;
}
