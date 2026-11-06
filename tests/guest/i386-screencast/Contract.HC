U0 SCLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
I64 SCCount()
{
  CSndData *d=scrncast.snd_head.next;I64 n=0;
  while(d!=&scrncast.snd_head && n<1000){n++;d=d->next;}
  return n;
}
U0 SCCheck()
{
  I64 v[20],before,flags=GetRFlags;U8 *s;CSndData *d;Bool old_dbg;
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
  before=SCCount;ScrnCast(TRUE,TRUE);
  v[12]=!Mute(TRUE) && IsMute && SCCount==before+2;
  Snd(60);v[13]=scrncast.ona==0 && SCCount==before+2;
  v[14]=Mute(FALSE) && !IsMute;
  Snd(60);old_dbg=DbgMode(TRUE);Snd(72);
  v[15]=!old_dbg && IsDbgMode && scrncast.ona==72 && SCCount==before+3;
  v[16]=DbgMode(FALSE) && !IsDbgMode;
  Snd;LBts(&sys_semas[SEMA_SND],0);SndRst;
  v[17]=!Bt(&sys_semas[SEMA_SND],0) && SCCount==before+5 && scrncast.snd_head.last->ona==0;
  v[18]=ScrnCast(FALSE,TRUE) && SCCount==before+5 && (InU8(0x61)&3)==0;
  v[19]=(GetRFlags&0x200)==(flags&0x200);
  s=MStrPrint("EXPORT screencast.bin %X %X\n",v,sizeof(v));SCLog(s);Free(s);
  SCLog("SCREENCAST DONE\n");Sleep(1000);
}
