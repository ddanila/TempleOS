U0 NoiseSleepLog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}

U0 NoiseSleepProbe()
{
  CTask *sound;
  U8 report[96];
  I64 start;
  NoiseSleepLog("TTF timer before control\n");
  Sleep(250);
  NoiseSleepLog("TTF timer after control\n");
  sound=Noise(250,34,41);
  if (!sound) {
    NoiseSleepLog("FAIL TTF Noise did not spawn\n");
    return;
  }
  start=cnts.jiffies;
  NoiseSleepLog("TTF timer before active noise\n");
  Sleep(250);
  StrPrint(report,"TTF timer after active noise %d\n",cnts.jiffies-start);
  NoiseSleepLog(report);
}
NoiseSleepProbe;
