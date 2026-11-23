I64 ttf_visibility_checks[12];

U0 TTFVisibilityProbe()
{
  I64 row,col;
  U8 line[128],*p;
  MemSet(ttf_visibility_checks,0,sizeof(ttf_visibility_checks));
  MemSet(terrain,PLAINS,sizeof(terrain));
  MemSet(units,0,sizeof(units));
  MemSet(vis_unit_bitmap,0,sizeof(vis_unit_bitmap));
  HexCentersCalc;
  cur_player=0;
  enemy_player=1;
  units[0][0].life=100;
  units[0][0].range=20;
  units[0][0].row=4;
  units[0][0].col=4;
  units[1][5].life=100;
  units[1][5].row=4;
  units[1][5].col=5;
  units[1][7].life=100;
  units[1][7].row=4;
  units[1][7].col=8;
  terrain[4][6]=MOUNTAINS;
  VRSetUp(0);
  VRSetUp(1);
  VisRecalc(VR_ALL_UNITS);
  ttf_visibility_checks[0]=Bt(&units[1][5].vis[0],0);
  ttf_visibility_checks[1]=Bt(&units[1][7].vis[0],0);
  VisRecalcMap(4,4);
  for (row=0;row<map_rows;row++)
    for (col=0;col<map_cols;col++)
      if (vis_map[row][col]) ttf_visibility_checks[2]++;
  ttf_visibility_checks[3]=vis_map[4][5];
  ttf_visibility_checks[4]=vis_map[4][8];
  ttf_visibility_checks[5]=VisRecalc(VR_ONE_FRIENDLY_UNIT,&units[0][0]);
  ttf_visibility_checks[6]=VisRecalc(VR_ONE_ENEMY_UNIT,&units[1][5]);
  terrain[4][6]=PLAINS;
  VisRecalc(VR_UPDATE_FRIENDLY_UNIT,&units[0][0]);
  ttf_visibility_checks[7]=Bt(&units[1][7].vis[0],0);
  units[0][0].life=0;
  VisRecalc(VR_FRIENDLY_UNIT_DIED,&units[0][0]);
  ttf_visibility_checks[8]=Bt(&units[0][0].vis[1],0);
  ttf_visibility_checks[9]=map_rows;
  ttf_visibility_checks[10]=map_cols;
  ttf_visibility_checks[11]=Bt(vis_unit_bitmap[0],7);
  StrPrint(line,"EXPORT TTFVisibility.bin %X 60\n",ttf_visibility_checks);
  for (p=line;*p;p++) OutU8(0xE9,*p);
  Sleep(2000);
  for (p="TTF visibility captured\n";*p;p++) OutU8(0xE9,*p);
}
TTFVisibilityProbe;
