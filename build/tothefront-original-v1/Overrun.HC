I64 ttf_overrun_pointer[2];
I64 ttf_vehicle=-1,ttf_infantry,ttf_overrun_row,ttf_overrun_col;

U0 TTFStageOverrun(CTask *owner)
{
  I64 i,j,dir,row,col,cost;
  F64 sx,sy,dx,dy;
  Unit *vehicle,*infantry;
  U8 line[256];
  for (j=0;j<UNITS_NUM;j++)
    if (units[1][j].infantry && units[1][j].life>0) break;
  if (j<UNITS_NUM) {
    infantry=&units[1][j];
    for (i=0;i<UNITS_NUM;i++) {
      vehicle=&units[0][i];
      if (vehicle->life>0 && vehicle->armor && !vehicle->infantry &&
          !vehicle->fired && vehicle->remaining_movement>=vehicle->movement>>1)
        for (dir=0;dir<6;dir++) {
          row=vehicle->row; col=vehicle->col;
          Toward(&row,&col,dir);
          if (0<=row<map_rows && 0<=col<map_cols && terrain[row][col]==PLAINS &&
              !UnitFind(row,col) && LOS(vehicle->row,vehicle->col,row,col)) {
            cost=HexMoveOneCost(vehicle,row,col,dir);
            if (cost<=vehicle->remaining_movement) {
              infantry->row=row;
              infantry->col=col;
              ttf_vehicle=i;
              ttf_infantry=j;
              ttf_overrun_row=row;
              ttf_overrun_col=col;
              RowCol2XY(&sx,&sy,vehicle->row,vehicle->col);
              RowCol2XY(&dx,&dy,row,col);
              StrPrint(line,"TTF aim overrun %X %d %d %d %d %d %d %d %d %d %d\n",
                  ttf_overrun_pointer,i,j,ToI64(sx)+x0+owner->pix_left,
                  ToI64(sy)+y0+owner->pix_top,ToI64(dx)+x0+owner->pix_left,
                  ToI64(dy)+y0+owner->pix_top,row,col,vehicle->life,infantry->life);
              TTFPhaseLog(line);
              return;
            }
          }
        }
    }
  }
  ttf_vehicle=-2;
  TTFPhaseLog("FAIL TTF no legal overrun fixture placement\n");
}

U0 TTFTrackOverrun(CTask *owner)
{
  Unit *vehicle,*infantry;
  U8 line[256];
  ttf_overrun_pointer[0]=ms.pos.x;
  ttf_overrun_pointer[1]=ms.pos.y;
  if (phase==PHASE_MOVE0 && ttf_vehicle==-1) TTFStageOverrun(owner);
  if (ttf_vehicle>=0) {
    vehicle=&units[0][ttf_vehicle];
    infantry=&units[1][ttf_infantry];
    if (vehicle->fired && infantry->fired &&
        ((vehicle->life==0 && alive_cnt[0]==UNITS_NUM-1) ||
         (infantry->life==0 && alive_cnt[1]==UNITS_NUM-1 &&
          vehicle->row==ttf_overrun_row && vehicle->col==ttf_overrun_col))) {
      StrPrint(line,"TTF overrun resolved %d %d %d %d %d %d %d\n",
          ttf_vehicle,ttf_infantry,vehicle->life,infantry->life,
          vehicle->row,vehicle->col,vehicle->remaining_movement);
      TTFPhaseLog(line);
      ttf_vehicle=-2;
    }
  }
}
