I64 ball_ui_pointer[2];

U0 BallUILog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}

U0 BallUIWatch(CTask *owner)
{
  U8 line[128];
  while (!owner->popup_task) Sleep(1);
  StrPrint(line,"BALL lighting %X\n",ball_ui_pointer);
  BallUILog(line);
  while (owner->popup_task) {
    ball_ui_pointer[0]=ms.pos.x;
    ball_ui_pointer[1]=ms.pos.y;
    Sleep(1);
  }
  BallUILog("BALL lighting selected\n");
}

U0 BallUIProbe()
{
  U8 line[128],*sprite;
  I32 *counts;
  I64 bytes;
  CTask *watch=Spawn(&BallUIWatch,Fs,"Ball lighting observer");
  BallUILog("BALL form start\n");
  sprite=BallGen;
  Kill(watch);
  if (!sprite || *sprite!=SPT_MESH) {
    BallUILog("FAIL BallGen did not return a mesh\n");
    return;
  }
  counts=(sprite+1)(I32 *);
  bytes=10+counts[0]*sizeof(CD3I32)+counts[1]*sizeof(CMeshTri);
  StrPrint(line,"EXPORT BallInteractive.bin %X %X\n",sprite,bytes);
  BallUILog(line);
  Sleep(2000);
  Free(sprite);
  BallUILog("BALL mesh returned\n");
}
