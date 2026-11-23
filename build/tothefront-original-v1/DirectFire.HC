I64 ttf_fire_pointer[2];
I64 ttf_attacker=-1,ttf_defender;

U0 TTFStageFire(CTask *owner)
{
  I64 i,j,dir,row,col;
  F64 sx,sy,ex,ey;
  Unit *attacker,*defender;
  U8 line[256];
  for (j=0;j<UNITS_NUM;j++)
    if (units[1][j].life>0) break;
  if (j<UNITS_NUM) {
    defender=&units[1][j];
    for (i=0;i<UNITS_NUM;i++) {
      attacker=&units[0][i];
      if (attacker->life>0 && !attacker->indirect_fire &&
          !attacker->fired && attacker->range>0)
        for (dir=0;dir<6;dir++) {
          row=attacker->row; col=attacker->col;
          Toward(&row,&col,dir);
          if (0<=row<map_rows && 0<=col<map_cols && !UnitFind(row,col) &&
              LOS(attacker->row,attacker->col,row,col)) {
            defender->row=row;
            defender->col=col;
            RowCol2XY(&sx,&sy,attacker->row,attacker->col);
            RowCol2XY(&ex,&ey,row,col);
            ttf_attacker=i;
            ttf_defender=j;
            StrPrint(line,"TTF fire %X %d %d %d %d %d %d %d\n",
                ttf_fire_pointer,i,j,ToI64(sx)+x0+owner->pix_left,ToI64(sy)+y0+owner->pix_top,
                ToI64(ex)+x0+owner->pix_left,ToI64(ey)+y0+owner->pix_top,defender->life);
            TTFPhaseLog(line);
            return;
          }
        }
    }
  }
  ttf_attacker=-2;
  TTFPhaseLog("FAIL TTF no legal direct-fire fixture placement\n");
}

U0 TTFTrackFire(CTask *owner)
{
  U8 line[160];
  ttf_fire_pointer[0]=ms.pos.x;
  ttf_fire_pointer[1]=ms.pos.y;
  if (phase==PHASE_DIRECT0 && ttf_attacker==-1) TTFStageFire(owner);
  if (ttf_attacker>=0 && units[0][ttf_attacker].fired && !target_unit) {
    StrPrint(line,"TTF fired %d %d %d %d\n",ttf_attacker,ttf_defender,
             target_hit,units[1][ttf_defender].life);
    TTFPhaseLog(line);
    ttf_attacker=-2;
  }
}
