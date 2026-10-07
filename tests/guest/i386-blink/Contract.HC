I64 JRContract(I64 unused)
{
  I64 flags=GetRFlags, saved, mask=0;
  SetRFlags(flags&~0x200);
  saved=cnts.jiffies;
  cnts.jiffies=1000;
  if(!Blink(0))mask|=1;
  cnts.jiffies=0;
  if(!Blink) {
    cnts.jiffies=200;
    if(Blink) {cnts.jiffies=400;if(!Blink)mask|=2;}
  }
  cnts.jiffies=500;
  if(Blink(1)) {cnts.jiffies=1000;if(!Blink(1))mask|=4;}
  cnts.jiffies=1000;
  if(Blink(0.5)) {cnts.jiffies=2000;if(!Blink(0.5))mask|=8;}
  cnts.jiffies=100;
  if(Blink(5)) {cnts.jiffies=200;if(!Blink(5))mask|=16;}
  cnts.jiffies=0x100000001;
  if(Blink(500)) {cnts.jiffies=0x100000002;if(!Blink(500))mask|=32;}
  cnts.jiffies=saved;
  SetRFlags(flags);
  return mask;
}
