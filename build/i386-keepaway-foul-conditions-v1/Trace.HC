U0 KAFoulConditions(F64 frame_time,F64 previous_hit,F64 dt,F64 closing,I64 team)
{
  U8 *line=MStrPrint("KEEP predicate t=%0.6f prev=%0.6f dt=%0.6f speed=%0.6f cooldown=%d booldt=%d team=%d\n",
                     frame_time,previous_hit,dt,closing/dt,
                     frame_time>previous_hit+1.0,!!dt,team);
  U8 *cursor=line;
  while(*cursor)OutU8(0xE9,*cursor++);
  Free(line);
}
