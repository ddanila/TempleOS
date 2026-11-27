I64 pk_reopened[9];
I64 pk_pointer[2];

U0 PKPersistenceWatch(U8 *)
{
  U8 *song=NULL;
  while (!pk_stage) Sleep(5);
  while (!(song=FileRead("~/Psalmody/Tmp.HC.Z"))) Sleep(20);
  Free(song);
  PKLog("PS saved\n");
  while (PKCount) Sleep(5);
  PKLog("PS cleared\n");
  PKLog(MStrPrint("PS pointer %X\n",pk_pointer));
  PKLog("PS pointer ready\n");
  while (PKCount!=2) {
    pk_pointer[0]=ms.pos.x;
    pk_pointer[1]=ms.pos.y;
    Sleep(5);
  }
  PKCapture(pk_reopened);
  PKLog(MStrPrint("EXPORT reopened.bin %X %X\n",pk_reopened,sizeof(pk_reopened)));
  PKLog("PS reopened\n");
  Sleep(1000);
}

U0 PsalmodyPersistence()
{
  I64 size;
  U8 *song;
  DirMk("~/Psalmody");
  Spawn(&PKPersistenceWatch,NULL,"Psalmody reopen observer");
  PsalmodyKeyboard;
  song=FileRead("~/Psalmody/Tmp.HC.Z",&size);
  if (!song || !size) throw('PsmSave',TRUE);
  PKLog(MStrPrint("EXPORT song.HC %X %X\n",song,size));
  PKLog("PS saved bytes\n");
  Sleep(1000);
  Free(song);
}
