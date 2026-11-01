I64 BPSeen;Bool BPReady,BPDone;
U0 BPObserver(U8 *unused)
{
  I64 i;BPReady=TRUE;
  for(i=0;i<55;i++) {if((InU8(0x61)&3)==3)BPSeen|=1;else BPSeen|=2;Sleep(20);}
  BPDone=TRUE;
}
I64 BEContract()
{
  I64 mask=0;F64 t0,dt;CTask *observer;
  Snd;BPSeen=0;BPReady=BPDone=FALSE;
  observer=Spawn(&BPObserver,NULL,"Beep observer",-1,Fs,8192);
  if(!observer)return 0;
  while(!BPReady)Sleep(10);
  t0=tS;Beep;dt=tS-t0;
  while(!BPDone)Sleep(10);
  if(BPSeen&1)mask|=1;
  if(BPSeen&2)mask|=2;
  if((InU8(0x61)&3)==0)mask|=4;
  if(dt>0.5 && dt<10)mask|=8;
  Beep(62,TRUE);
  if((InU8(0x61)&3)==0)mask|=16;
  Snd;return mask;
}
I64 BECheck(){I64 v=BEContract;if(v!=31)throw('Beep',TRUE);return v;}
