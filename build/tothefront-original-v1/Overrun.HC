I64 ttf_assault_pointer[2];
I64 ttf_assault_attacker=-1,ttf_assault_defender,ttf_assault_row,ttf_assault_col;

U0 TTFStageAssault(CTask *owner)
{
  I64 i,j,dir,row,col,cost;
  F64 sx,sy,dx,dy;
  Unit *attacker,*defender;
  U8 line[256];
  for (j=0;j<UNITS_NUM;j++)
    if (units[1][j].life>0 &&
        (TTF_CLOSE_ASSAULT && units[1][j].armor ||
         !TTF_CLOSE_ASSAULT && units[1][j].infantry)) break;
  if (j<UNITS_NUM) {
    defender=&units[1][j];
    for (i=0;i<UNITS_NUM;i++) {
      attacker=&units[0][i];
      if (attacker->life>0 && (TTF_CLOSE_ASSAULT && attacker->infantry ||
          !TTF_CLOSE_ASSAULT && attacker->armor && !attacker->infantry) &&
          !attacker->fired && attacker->remaining_movement>=attacker->movement>>1)
        for (dir=0;dir<6;dir++) {
          row=attacker->row; col=attacker->col;
          Toward(&row,&col,dir);
          if (0<=row<map_rows && 0<=col<map_cols && terrain[row][col]==PLAINS &&
              !UnitFind(row,col) && LOS(attacker->row,attacker->col,row,col)) {
            cost=HexMoveOneCost(attacker,row,col,dir);
            if (cost<=attacker->remaining_movement) {
              defender->row=row;
              defender->col=col;
              ttf_assault_attacker=i;
              ttf_assault_defender=j;
              ttf_assault_row=row;
              ttf_assault_col=col;
              RowCol2XY(&sx,&sy,attacker->row,attacker->col);
              RowCol2XY(&dx,&dy,row,col);
              StrPrint(line,"TTF aim occupation %X %d %d %d %d %d %d %d %d %d %d\n",
                  ttf_assault_pointer,i,j,ToI64(sx)+x0+owner->pix_left,
                  ToI64(sy)+y0+owner->pix_top,ToI64(dx)+x0+owner->pix_left,
                  ToI64(dy)+y0+owner->pix_top,row,col,attacker->life,defender->life);
              TTFPhaseLog(line);
              return;
            }
          }
        }
    }
  }
  ttf_assault_attacker=-2;
  TTFPhaseLog("FAIL TTF no legal occupation fixture placement\n");
}

U0 TTFTrackAssault(CTask *owner)
{
  Unit *attacker,*defender;
  U8 line[256];
  ttf_assault_pointer[0]=ms.pos.x;
  ttf_assault_pointer[1]=ms.pos.y;
  if (phase==PHASE_MOVE0 && ttf_assault_attacker==-1) TTFStageAssault(owner);
  if (ttf_assault_attacker>=0) {
    attacker=&units[0][ttf_assault_attacker];
    defender=&units[1][ttf_assault_defender];
    if (attacker->fired && defender->fired &&
        ((attacker->life==0 && alive_cnt[0]==UNITS_NUM-1) ||
         (defender->life==0 && alive_cnt[1]==UNITS_NUM-1 &&
          attacker->row==ttf_assault_row && attacker->col==ttf_assault_col))) {
      StrPrint(line,"TTF occupation resolved %d %d %d %d %d %d %d\n",
          ttf_assault_attacker,ttf_assault_defender,attacker->life,defender->life,
          attacker->row,attacker->col,attacker->remaining_movement);
      TTFPhaseLog(line);
      ttf_assault_attacker=-2;
    }
  }
}
