U0 SPLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 SpeakerClockProbe()
{
  U8 line[100];
  StrPrint(line,"SPEAKER JIFFIES %X\n",&cnts.jiffies);
  SPLog(line);
  Noise(250,86,86);
  Sleep(50);
  Noise(250,86,86);
  Sleep(300);
  SPLog("SPEAKER finished\n");
}
