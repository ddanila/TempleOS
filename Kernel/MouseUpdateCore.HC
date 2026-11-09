#include "/Kernel/MousePositionCore.HC"

U0 GridInit()
{//Init mouse grid struct. See $LK,"::/Demo/Graphics/Grid.HC"$.
  ms_grid.x=ms_grid.y=ms_grid.z=8;
  ms_grid.x_offset=ms_grid.y_offset=ms_grid.z_offset=0;
  ms_grid.x_speed =ms_grid.y_speed =ms_grid.z_speed =1;
  ms_grid.show=ms_grid.snap=ms_grid.coord=FALSE;
}

U0 MsUpdate(I64 x,I64 y,I64 z,Bool l,Bool r)
{
  MousePositionCore(&ms,&ms_grid,x,y,z,text.cols,text.rows);
  ms.lb=l;
  ms.rb=r;
  LBEqu(&kbd.scan_code,SCf_MS_L_DOWN,ms.lb);
  LBEqu(&kbd.scan_code,SCf_MS_R_DOWN,ms.rb);
}
