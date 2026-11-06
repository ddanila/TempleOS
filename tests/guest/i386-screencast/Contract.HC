U0 SCLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
I64 SCCount()
{
  CSndData *d=scrncast.snd_head.next;I64 n=0;
  while(d!=&scrncast.snd_head && n<1000){n++;d=d->next;}
  return n;
}
U0 SCCheck()
{
  I64 v[12],before;U8 *s;CSndData *d;
  ScrnCast(FALSE,TRUE);Mute(FALSE);Snd(48);before=SCCount;
  v[0]=!ScrnCast(TRUE,TRUE,"B:/Tmp/SC%X.GR");
  v[1]=scrncast.record && scrncast.just_audio;
  v[2]=scrncast.snd_head.ona==48 && scrncast.ona==0;
  v[3]=SCCount==before+1 && scrncast.snd_head.last->ona==0;
  Snd(60);Snd(60);Snd;
  v[4]=SCCount==before+4;
  d=scrncast.snd_head.last;
  v[5]=d->ona==0 && d->last->ona==60 && d->last->last->ona==60;
  v[6]=d->tS>=d->last->tS>=d->last->last->tS>=scrncast.t0_tS;
  v[7]=ScrnCast(TRUE,TRUE);
  v[8]=!scrncast.record && SCCount==before+4;
  v[9]=!ScrnCast(FALSE,TRUE) && SCCount==before+4;
  v[10]=!ScrnCast(TRUE,TRUE) && SCCount==before+5;
  v[11]=ScrnCast(FALSE,TRUE) && !scrncast.record && SCCount==before+5;
  s=MStrPrint("EXPORT screencast.bin %X %X\n",v,sizeof(v));SCLog(s);Free(s);
  SCLog("SCREENCAST DONE\n");Sleep(1000);
}
