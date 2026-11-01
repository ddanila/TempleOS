U0 GridInit()
{//Init mouse grid struct. See $LK,"::/Demo/Graphics/Grid.HC"$.
  ms_grid.x=ms_grid.y=ms_grid.z=8;
  ms_grid.x_offset=ms_grid.y_offset=ms_grid.z_offset=0;
  ms_grid.x_speed =ms_grid.y_speed =ms_grid.z_speed =1;
  ms_grid.show=ms_grid.snap=ms_grid.coord=FALSE;
}

U0 MsUpdate(I64 x,I64 y,I64 z,Bool l,Bool r)
{
  ms.presnap.x=ToI64(ms.scale.x*x)+ms.offset.x;
  ms.presnap.y=ToI64(ms.scale.y*y)+ms.offset.y;
  ms.presnap.z=ToI64(ms.scale.z*z)+ms.offset.z;
  if (ms_grid.snap) {
    ms.pos.x=Trunc(ms.presnap.x/ms_grid.x)*ms_grid.x+ms_grid.x_offset;
    ms.pos.y=Trunc(ms.presnap.y/ms_grid.y)*ms_grid.y+ms_grid.y_offset;
    ms.pos.z=Trunc(ms.presnap.z/ms_grid.z)*ms_grid.z+ms_grid.z_offset;
  } else {
    ms.pos.x=ms.presnap.x;
    ms.pos.y=ms.presnap.y;
    ms.pos.z=ms.presnap.z;
  }

  ms.pos.x=ClampI64(ms.pos.x,0,GR_WIDTH-1);
  ms.pos.y=ClampI64(ms.pos.y,0,GR_HEIGHT-1);
  ms.pos_text.x=ms.pos.x/FONT_WIDTH;
  if (ms.pos_text.x>=text.cols) {
    ms.pos_text.x=text.cols-1;
    ms.pos.x=text.cols*FONT_WIDTH-1;
  }
  ms.pos_text.y=ms.pos.y/FONT_HEIGHT;
  if (ms.pos_text.y>=text.rows) {
    ms.pos_text.y=text.rows-1;
    ms.pos.y=text.rows*FONT_HEIGHT-1;
  }
  ms.lb=l;
  ms.rb=r;
  LBEqu(&kbd.scan_code,SCf_MS_L_DOWN,ms.lb);
  LBEqu(&kbd.scan_code,SCf_MS_R_DOWN,ms.rb);
}
