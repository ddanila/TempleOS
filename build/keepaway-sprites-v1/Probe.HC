U0 KAOut(U8 *s) {while(*s)OutU8(0xE9,*s++);}

U0 KAProbe()
{
  I64 i,j;
  U8 line[128],*sprite;
  for(i=0;i<=LAST_STOPPED_DRIBBLING;i++)
    for(j=0;j<2;j++) {
      sprite=imgs[i].img[j];
      StrPrint(line,"EXPORT frame-%02d-%d.bin %X 20\n",i,j,sprite);
      KAOut(line);
      StrPrint(line,"SPRITE size %d %d %d\n",i,j,SpriteSize(sprite));
      KAOut(line);
    }
  KAOut("KEEP sprites done\n");
}
