U8 *progress_frames[4];
I64 CaptureProgressFrames()
{
  CProgress saved[4];CDC *dc=DCNew(640,480);I64 i;
  MemCpy(saved,sys_progresses,sizeof(saved));
  for(i=0;i<4;i++) {
    MemSet(sys_progresses,0,sizeof(saved));
    DCFill(dc,WHITE);
    switch(i) {
      case 0: sys_progresses[0].max=100;sys_progresses[0].val=50;break;
      case 1: sys_progresses[0].max=3;sys_progresses[0].val=9;StrCpy(sys_progresses[0].desc,"Label");break;
      case 2: sys_progresses[1].max=1;sys_progresses[1].val=1;sys_progresses[1].tf=1.25;break;
      case 3: sys_progresses[0].max=4;sys_progresses[0].val=1;
        sys_progresses[1].max=5;sys_progresses[1].val=2;
        sys_progresses[2].max=6;sys_progresses[2].val=3;
        sys_progresses[3].max=7;sys_progresses[3].val=4;break;
    }
    DrawProgressBars(dc);progress_frames[i]=MAlloc(640*480);
    MemCpy(progress_frames[i],dc->body,640*480);
  }
  MemCpy(sys_progresses,saved,sizeof(saved));DCDel(dc);return 1;
}
U0 FreeProgressFrames(){I64 i;for(i=0;i<4;i++){Free(progress_frames[i]);progress_frames[i]=NULL;}}
