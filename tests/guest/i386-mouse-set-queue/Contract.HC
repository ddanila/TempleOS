I64 mp_mask;
U0 MPReset()
{
  MemSet(&mp_packets,0,sizeof(CMPPackets));MemSet(&mp_irq,0,sizeof(CMPState));
  MemSet(&mp_ms,0,sizeof(CMsStateGlbls));MemSet(&mp_grid,0,sizeof(CGridGlbls));
  MemSet(mp_z,0,sizeof(mp_z));mp_pending=FALSE;
  mp_scale.x=mp_scale.y=0.5;mp_scale.z=1.0;
  mp_hard.x=mp_irq.x=640;mp_hard.y=mp_irq.y=480;mp_hard.z=mp_irq_z=0;
  mp_grid.x=mp_grid.y=mp_grid.z=8.0;mp_grid.x_speed=mp_grid.y_speed=mp_grid.z_speed=1.0;
  mp_ms.scale.x=mp_ms.scale.y=mp_ms.scale.z=1.0;
}
U0 MouseSetQueueContract()
{
  I64 raw_a[4],raw_b[4],x=ms.pos.x,y=ms.pos.y,z=ms.pos.z,lb=ms.lb,rb=ms.rb;
  I64 flags,before=Fs->data_heap->used_u8s;Bool raw_ok,logical_ok,irq_ok;
  U8 *s;
  mp_mask=0;MPReset;
  mp_packets.read=63;mp_packets.write=1;mp_packets.count=2;mp_packets.losses=7;mp_packets.last_buttons=3;
  mp_packets.events[63].x=644;mp_packets.events[63].y=484;mp_z[63]=1;
  mp_packets.events[63].stamp=11;mp_packets.events[63].buttons=2;
  mp_packets.events[0].x=648;mp_packets.events[0].y=480;mp_z[0]=2;
  mp_packets.events[0].stamp=22;mp_packets.events[0].buttons=1;
  mp_packets.events[62].x=9999;mp_packets.events[1].x=8888;
  mp_irq.x=648;mp_irq.y=480;mp_irq_z=2;mp_irq.buttons=4;mp_irq.serial=123;
  MPSet(100,120,3,TRUE,FALSE);
  if(mp_irq.x==208&&mp_irq.y==240&&mp_irq_z==5&&mp_irq.buttons==5&&mp_irq.serial==123&&
      mp_pending&&mp_set.x==200&&mp_set.y==240&&mp_set.z==3&&mp_buttons==5&&
      mp_packets.events[63].x==204&&mp_packets.events[63].y==244&&mp_z[63]==4&&
      mp_packets.events[0].x==208&&mp_packets.events[0].y==240&&mp_z[0]==5)mp_mask|=1;
  MPSet(200,300,10,FALSE,TRUE);
  if(mp_irq.x==408&&mp_irq.y==600&&mp_irq_z==12&&mp_irq.buttons==6&&mp_pending&&
      mp_set.x==400&&mp_set.y==600&&mp_set.z==10&&mp_buttons==6&&mp_stamp==12345&&mp_input.timestamp==12345&&
      mp_packets.events[63].x==404&&mp_packets.events[63].y==604&&mp_z[63]==11&&
      mp_packets.events[0].x==408&&mp_packets.events[0].y==600&&mp_z[0]==12&&
      mp_packets.read==63&&mp_packets.write==1&&mp_packets.count==2&&mp_packets.losses==7&&mp_packets.last_buttons==3&&
      mp_packets.events[63].stamp==11&&mp_packets.events[0].stamp==22&&
      mp_packets.events[63].buttons==2&&mp_packets.events[0].buttons==1&&
      mp_packets.events[62].x==9999&&mp_packets.events[1].x==8888)mp_mask|=2;
  mp_hard.x=408;mp_hard.y=600;mp_hard.z=12;mp_pending=FALSE;
  mp_packets.count=0;mp_packets.read=mp_packets.write=17;MPSet(320,240,0,FALSE,FALSE);
  if(mp_irq.x==640&&mp_irq.y==480&&mp_irq_z==0&&mp_set.x==640&&mp_set.y==480&&mp_set.z==0&&
      !mp_packets.count&&mp_packets.read==17&&mp_packets.write==17)mp_mask|=4;
  MPReset;mp_grid.x_speed=1.5;mp_grid.y_speed=2.5;mp_grid.z_speed=1.5;MPSet(101,103,7,FALSE,FALSE);
  if(mp_set.x==134&&mp_set.y==82&&mp_set.z==4&&mp_irq.x==134&&mp_irq.y==82&&mp_irq_z==4)mp_mask|=8;
  MPReset;MPSet(-10,500,0,FALSE,FALSE);
  if(mp_ms.offset.x==8&&mp_ms.offset.y==-17&&mp_set.x==-20&&mp_set.y==1000)mp_mask|=16;
  flags=GetRFlags;SetRFlags(flags&~0x200);
  raw_ok=MouseGet(&raw_a[0],&raw_a[1],&raw_a[2],&raw_a[3]);MsSet(100,120,3,TRUE,FALSE);
  raw_ok=raw_ok&&MouseGet(&raw_b[0],&raw_b[1],&raw_b[2],&raw_b[3])&&!MemCmp(raw_a,raw_b,32);
  logical_ok=ms.pos.x==100&&ms.pos.y==120&&ms.pos.z==3&&ms.lb&&!ms.rb&&Bt(&kbd.scan_code,SCf_MS_L_DOWN);
  irq_ok=!(GetRFlags&0x200);MsSet(x,y,z,lb,rb);irq_ok=irq_ok&&!(GetRFlags&0x200);SetRFlags(flags);
  if(raw_ok&&logical_ok&&irq_ok&&Fs->data_heap->used_u8s==before)mp_mask|=32;
  U8 *line;
  s=MStrPrint("EXPORT set-queue-mask.bin %X 8\n",&mp_mask);line=s;while(*line)OutU8(0xE9,*line++);Free(s);
}
