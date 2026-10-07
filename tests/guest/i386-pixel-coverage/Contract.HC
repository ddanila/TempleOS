#include "/Adam/Gr/GrPixelCoverageCore.HC"
I64 JRContract(I64 unused)
{
  CTask task;
  U16 *area=CAlloc(TEXT_COLS*TEXT_ROWS*sizeof(U16)),*saved=gr.win_z_buf;
  I64 flags=GetRFlags,mask=0,i,x,y;
  Bool expected,ok=TRUE;
  MemSet(&task,0,sizeof(task));SetRFlags(flags&~0x200);gr.win_z_buf=area;
  task.win_z_num=0;
  if(!IsPixCovered0(&task,0,0) && !GrPixelCoveredCore(&task,0,0))mask|=1;
  area[0]=1;
  if(IsPixCovered0(&task,7,7) && GrPixelCoveredCore(&task,7,7))mask|=2;
  task.win_z_num=1;
  if(!IsPixCovered0(&task,0,0) && !GrPixelCoveredCore(&task,0,0))mask|=4;
  area[0]=32768;task.win_z_num=32767;
  if(IsPixCovered0(&task,0,0) && GrPixelCoveredCore(&task,0,0))mask|=8;
  area[0]=65535;task.win_z_num=65535;
  if(!IsPixCovered0(&task,0,0) && !GrPixelCoveredCore(&task,0,0))mask|=16;
  for(i=0;i<TEXT_COLS*TEXT_ROWS;i++)area[i]=(i*997+12345)&65535;
  task.win_z_num=32768;
  for(y=0;y<480;y++)for(x=0;x<640;x++) {
    expected=32768<area[(y/8)*80+x/8];
    if(IsPixCovered0(&task,x,y)!=expected || GrPixelCoveredCore(&task,x,y)!=expected)ok=FALSE;
  }
  if(ok)mask|=32;
  gr.win_z_buf=saved;SetRFlags(flags);Free(area);return mask;
}
