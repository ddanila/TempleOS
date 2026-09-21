Bool TextBaseCheckEqual(U32 *base,U32 *expected)
{
  I64 i;
  if(base[-1]!=0xAB1234CD || base[4800]!=0xEF567890) return FALSE;
  for(i=0;i<4800;i++) if(base[i]!=expected[i]) return FALSE;
  return TRUE;
}
I64 TextBaseCheck(U32 *base,
  Bool (*put)(CTask *task,Bool border,I64 x,I64 y,I64 value),
  Bool (*str)(CTask *task,I64 x,I64 y,I64 length,I64 attr,U8 *src),
  Bool (*attrs)(CTask *task,I64 x,I64 y,I64 length,U32 *src),
  Bool (*fill)(CTask *task,I64 x,I64 y,I64 length,I64 attr))
{
  CTask task;
  U32 expected[4800],values[4];
  I64 i;
  MemSet(&task,0,sizeof(task));
  task.win_left=2; task.win_right=6; task.win_top=3; task.win_bottom=5;
  for(i=0;i<4800;i++) base[i]=expected[i]=0x13579B00;
  expected[242]=0x12345678;
  if(!(*put)(&task,FALSE,0,0,0x12345678) || !TextBaseCheckEqual(base,expected)) return -1;
  if((*put)(&task,FALSE,-1,0,9) || (*put)(&task,FALSE,5,0,9) ||
      !TextBaseCheckEqual(base,expected)) return -2;
  expected[161]=0xABCDEF12; expected[487]=0x1234;
  if(!(*put)(&task,TRUE,-1,-1,0xABCDEF12) || !(*put)(&task,TRUE,5,3,0x1234) ||
      !TextBaseCheckEqual(base,expected)) return -3;
  task.scroll_x=-8; task.scroll_y=8; expected[322]=0x99;
  if(!(*put)(&task,FALSE,1,0,0x99) || !TextBaseCheckEqual(base,expected)) return -4;
  task.scroll_x=task.scroll_y=0;
  for(i=0;i<4;i++) expected[242+i]=0xAABBCC00+'C'+i;
  if(!(*str)(&task,-2,0,6,0xAABBCCFF,"ABCDEFGH") || !TextBaseCheckEqual(base,expected)) return -5;
  expected[245]=0xDD00+'A'; expected[246]=0xDD00+'B';
  if(!(*str)(&task,3,0,4,0xDDFF,"ABCD") || !TextBaseCheckEqual(base,expected)) return -6;
  task.win_left=-2; task.win_right=5;
  for(i=0;i<4;i++) expected[240+i]=0xEE00+'C'+i;
  if(!(*str)(&task,0,0,6,0xEEFF,"ABCDEFGH") || !TextBaseCheckEqual(base,expected)) return -7;
  task.win_left=78; task.win_right=85;
  expected[318]=0x2200+'A'; expected[319]=0x2200+'B';
  if(!(*str)(&task,0,0,6,0x22FF,"ABCDEFGH") || !TextBaseCheckEqual(base,expected)) return -8;
  if((*put)(&task,FALSE,2,0,7) || (*str)(&task,0,-1,3,0,"abc") ||
      (*str)(&task,0,0,0,0,0) || (*fill)(&task,0,0,-1,0) || !TextBaseCheckEqual(base,expected)) return -9;
  task.win_left=2; task.win_right=6;
  values[0]=0x12345678; values[1]=0xABCDEF00; values[2]=0x89ABCDEF; values[3]=0x98765432;
  for(i=0;i<3;i++) expected[402+i]=values[i+1];
  if(!(*attrs)(&task,-1,2,4,values) || !TextBaseCheckEqual(base,expected)) return -10;
  base[242]=expected[242]=0xCC00; base[243]=expected[243]=0;
  base[244]=expected[244]=0x42; base[245]=expected[245]=0;
  expected[242]=expected[243]=0xFACE1200;
  if(!(*fill)(&task,0,0,4,0xFACE1200) || !TextBaseCheckEqual(base,expected) ||
      !(*fill)(&task,2,0,2,0x9900) || !TextBaseCheckEqual(base,expected)) return -11;
  expected[322]=0x99887700+'A'; expected[323]=0x99887700; expected[324]=0x99887700+'B';
  if(!(*str)(&task,0,1,3,0x998877FF,"A\0B") || !TextBaseCheckEqual(base,expected)) return -12;
  for(i=0;i<4800;i++) base[i]=0;
  return 12;
}
