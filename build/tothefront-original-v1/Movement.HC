I64 ttf_pointer[2];
I64 ttf_move_index=-1,ttf_move_row,ttf_move_col;

U0 TTFPickMove(CTask *owner)
{
  I64 i,dir,row,col,cost;
  F64 sx,sy,dx,dy;
  I64 points;
  Unit *unit;
  U8 line[256];
  for (i=0;i<UNITS_NUM;i++) {
    unit=&units[cur_player][i];
    if (unit->infantry && unit->life>0 && unit->remaining_movement>0)
      for (dir=0;dir<6;dir++) {
        row=unit->row; col=unit->col;
        Toward(&row,&col,dir);
        if (0<=row<map_rows && 0<=col<map_cols && !UnitFind(row,col)) {
          cost=HexMoveOneCost(unit,row,col,dir);
          if (cost<=unit->remaining_movement) {
            RowCol2XY(&sx,&sy,unit->row,unit->col);
            RowCol2XY(&dx,&dy,row,col);
            ttf_move_index=i;
            ttf_move_row=row;
            ttf_move_col=col;
            points=unit->remaining_movement-cost;
            StrPrint(line,"TTF move %X %d %d %d %d %d %d %d %d\n",
                ttf_pointer,i,ToI64(sx)+x0+owner->pix_left,ToI64(sy)+y0+owner->pix_top,
                ToI64(dx)+x0+owner->pix_left,ToI64(dy)+y0+owner->pix_top,row,col,points);
            TTFPhaseLog(line);
            return;
          }
        }
      }
  }
  TTFPhaseLog("FAIL TTF no legal infantry move\n");
}

U0 TTFTrackMove(CTask *owner)
{
  Unit *unit;
  U8 line[128];
  ttf_pointer[0]=ms.pos.x;
  ttf_pointer[1]=ms.pos.y;
  if (phase==PHASE_MOVE0 && ttf_move_index==-1)
    TTFPickMove(owner);
  if (ttf_move_index>=0) {
    unit=&units[0][ttf_move_index];
    if (unit->row==ttf_move_row && unit->col==ttf_move_col && !moving) {
      StrPrint(line,"TTF moved %d %d %d %d\n",ttf_move_index,unit->row,unit->col,
          unit->remaining_movement);
      TTFPhaseLog(line);
      ttf_move_index=-2;
    }
  }
}
