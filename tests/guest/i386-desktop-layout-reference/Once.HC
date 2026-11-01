U0 LayoutReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
I64 *v=CAlloc(664),count=0,i=0;
CTask *t=sys_winmgr_task;
v[1]=Fs==adam_task;
do {
  if(Bt(&t->display_flags,DISPLAYf_SHOW)&&!Bt(&t->win_inhibit,WIf_SELF_FOCUS)) {
    if(count<16) {
      i=3+count*5;
      v[i]=t->win_left;v[i+1]=t->win_right;v[i+2]=t->win_top;
      v[i+3]=t->win_bottom;v[i+4]=Bt(&t->display_flags,DISPLAYf_NO_BORDER);
    }
    count++;
  }
  t=t->last_task;
} while(t!=sys_winmgr_task);
v[0]=count;v[2]=Fs->win_height;
U8 *line=MStrPrint("EXPORT desktop-layout.bin %X %X\n",v,664);LayoutReport(line);Free(line);
LayoutReport("DONE original desktop layout\n");
