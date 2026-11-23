Bool ttf_game_over_logged=FALSE;

U0 TTFStageLastDefender(I64 defender)
{
  I64 i;
  for (i=0;i<UNITS_NUM;i++)
    if (i!=defender) units[1][i].life=0;
  alive_cnt[1]=1;
}

U0 TTFTrackGameOver()
{
  U8 line[128];
  if (!ttf_game_over_logged && !StrCmp(msg_buf,"Game Over")) {
    StrPrint(line,"TTF game over %d %d %d %d\n",turn,phase,alive_cnt[0],alive_cnt[1]);
    TTFPhaseLog(line);
    ttf_game_over_logged=TRUE;
  }
}
