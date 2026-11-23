I64 ttf_ai_pointer[2];

U0 TTFAIStart()
{
  U8 line[128];
  StrPrint(line,"TTF AI pointer %X\n",ttf_ai_pointer);
  TTFPhaseLog(line);
}

U0 TTFAIReadPointer()
{
  ttf_ai_pointer[0]=ms.pos.x;
  ttf_ai_pointer[1]=ms.pos.y;
}

U0 TTFAIExport()
{
  I64 i;
  U8 line[128];
  if (turn==1 && (phase==PHASE_MOVE0 || phase==PHASE_MOVE1))
    for (i=0;i<UNITS_NUM;i++) {
      StrPrint(line,"TTF AI unit %d %d %d %d %d %d\n",phase,i,
          units[0][i].row,units[0][i].col,units[0][i].life,
          units[0][i].remaining_movement);
      TTFPhaseLog(line);
    }
}
