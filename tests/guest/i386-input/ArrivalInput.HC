//Check publication time against an independent controlled clock, not slot indexes.
I64 ArrivalInputTest()
{
  CI386KbcInput stream;
  I64 clock=0,*previous=scheduler.jiffies,i,cycle;
  U8 data,status;
  U32 saved=GetRFlags;
  stream.scheduler=0;
  scheduler.jiffies=&clock;
  if(!I386KbcInputInit(&stream,&scheduler)) return 240;
  //Start away from zero and cross the ring boundary on every full batch.
  stream.queue.head=37;
  for(cycle=0;cycle<3;cycle++) {
    for(i=0;i<64;i++) {
      clock=0x100000000+cycle*1000+i;
      if(!I386KbcInputPut(&stream,i,0x81)) return 241;
    }
    clock=0x700000000;
    if(I386KbcInputPut(&stream,0xFF,0xFF) || stream.queue.count!=64 ||
        stream.queue.dropped!=cycle+1) return 242;
    //Reading long after publication must preserve all retained timestamps.
    for(i=0;i<64;i++) {
      if(!I386KbcInputRead(&stream,&data,&status,FALSE) || data!=i || status!=0x81 ||
          stream.last_arrival_jiffy!=0x100000000+cycle*1000+i) return 243;
    }
    if(stream.queue.count || stream.queue.head!=37 || (GetRFlags&512)!=(saved&512)) return 244;
  }
  //No clock means a fresh zero timestamp, never the previous slot value.
  scheduler.jiffies=0;
  if(!I386KbcInputPut(&stream,0x33,1) || !I386KbcInputRead(&stream,&data,&status,FALSE) ||
      data!=0x33 || status!=1 || stream.last_arrival_jiffy) return 245;
  scheduler.jiffies=previous;
  return 0;
}
