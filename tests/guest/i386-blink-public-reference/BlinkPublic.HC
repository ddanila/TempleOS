I64 BPContract()
{
  I64 mask=0,seen=0,i;Bool a,b;
  if(!Blink(0))mask|=1;
  for(i=0;i<25;i++){a=Blink(10);seen|=1<<a;Sleep(20);}
  if(seen==3)mask|=2;
  seen=0;
  for(i=0;i<35;i++) {
    a=Blink;b=Blink(2.5);if(a==b)seen|=1<<a;
    Sleep(20);
  }
  if(seen==3)mask|=4;
  seen=0;
  for(i=0;i<20;i++){a=Blink(5);seen|=1<<a;Sleep(20);}
  if(seen==3 && !Blink(0.0))mask|=8;
  return mask;
}
I64 BPCheck(){I64 v=BPContract;if(v!=15)throw('Blink',TRUE);return v;}
