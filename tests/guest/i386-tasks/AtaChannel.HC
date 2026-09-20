CI386AtaChannel ata_channel,ata_other;
CI386OwnedTask *ata_tasks[3];
U32 ata_order,ata_done;
U0 AtaChannelWorker(I64 id)
{
  U32 wanted=0;
  if(id==1) { SetRFlags(GetRFlags|0x200); wanted=0x200; }
  if(!I386AtaChannelAcquire(&ata_channel) || ata_channel.owner!=I386TaskSelf ||
      I386TaskSelf->io_locks!=1 || (GetRFlags&0x200)!=wanted ||
      I386AtaChannelAcquire(&ata_channel) || I386AtaChannelClose(&ata_channel) ||
      I386SchedFinish(&scheduler) || I386TaskSelf->finishing) { errors++; return; }
  ata_order=ata_order*10+id+1;
  if(!I386SchedYield(&scheduler) || ata_channel.owner!=I386TaskSelf ||
      I386TaskSelf->io_locks!=1 || (GetRFlags&0x200)!=wanted ||
      !I386AtaChannelRelease(&ata_channel) || I386TaskSelf->io_locks ||
      I386AtaChannelRelease(&ata_channel) || (GetRFlags&0x200)!=wanted) errors++;
  ata_done++;
}
I64 AtaChannelTest()
{
  CI386Heap heap;
  I64 i;
  U32 saved;
  if(!I386HeapInit(&heap,0x60000,32768) ||
      I386AtaChannelInit(0,&scheduler,0) || I386AtaChannelInit(&ata_channel,0,0) ||
      I386AtaChannelInit(&ata_channel,&scheduler,-1) || I386AtaChannelInit(&ata_channel,&scheduler,2) ||
      I386AtaChannelAcquire(&ata_channel) || I386AtaChannelRelease(&ata_channel) ||
      I386AtaChannelClose(&ata_channel)) return 60;
  if(!I386AtaChannelInit(&ata_channel,&scheduler,0) || ata_channel.io!=0x1F0 || ata_channel.control!=0x3F6 ||
      I386AtaChannelInit(&ata_channel,&scheduler,0) || !I386AtaChannelAcquire(&ata_channel) ||
      scheduler.current->io_locks!=1 || I386AtaChannelAcquire(&ata_channel) ||
      I386AtaChannelClose(&ata_channel)) return 61;
  for(i=0;i<3;i++) {
    ata_tasks[i]=I386TaskSpawn(&scheduler,&heap,8192,&AtaChannelWorker,i);
    if(!ata_tasks[i]) return 62;
  }
  if(!I386SchedYield(&scheduler) || ata_order || ata_done ||
      ata_channel.owner!=scheduler.current || !ata_channel.head || !ata_channel.tail) return 63;
  for(i=0;i<3;i++) if(!ata_tasks[i]->task.blocked || ata_tasks[i]->task.io_locks || ata_tasks[i]->task.finished) return 64;
  if(ata_channel.head->task!=&ata_tasks[0]->task || ata_channel.tail->task!=&ata_tasks[2]->task) return 65;
  //A spurious wake must neither grant ownership nor change FIFO order.
  if(!I386SchedWake(&scheduler,&ata_tasks[1]->task) || !I386SchedYield(&scheduler) ||
      !ata_tasks[1]->task.blocked || ata_order ||
      ata_channel.head->task!=&ata_tasks[0]->task || ata_channel.tail->task!=&ata_tasks[2]->task) return 66;
  if(!I386AtaChannelRelease(&ata_channel) || scheduler.current->io_locks ||
      ata_channel.owner!=&ata_tasks[0]->task || ata_tasks[0]->task.io_locks!=1 ||
      I386AtaChannelAcquire(&ata_channel) || I386AtaChannelRelease(&ata_channel)) return 67;
  for(i=0;i<3;i++) {
    if(!I386SchedYield(&scheduler) || errors || ata_channel.owner!=&ata_tasks[i]->task ||
        ata_tasks[i]->task.finished || ata_tasks[i]->task.io_locks!=1 ||
        I386TaskDestroy(ata_tasks[i]) || I386AtaChannelAcquire(&ata_channel)) return 68;
    if((i==0 && ata_order!=1) || (i==1 && ata_order!=12) || (i==2 && ata_order!=123)) return 69;
  }
  if(!I386SchedYield(&scheduler) || errors || ata_done!=3 || ata_channel.owner ||
      ata_channel.head || ata_channel.tail || scheduler.current->io_locks) return 70;
  for(i=0;i<3;i++) {
    if(!ata_tasks[i]->task.finished || ata_tasks[i]->task.io_locks) return 71;
    ata_tasks[i]->task.io_locks=1;
    if(I386TaskDestroy(ata_tasks[i])) return 72;
    ata_tasks[i]->task.io_locks=0;
    if(!I386TaskDestroy(ata_tasks[i])) return 73;
  }
  if(heap.used || heap.allocations || !I386HeapValid(&heap)) return 74;
  if(!I386AtaChannelClose(&ata_channel) || ata_channel.signature || ata_channel.scheduler ||
      !I386AtaChannelInit(&ata_channel,&scheduler,0) ||
      !I386AtaChannelInit(&ata_other,&scheduler,1) || ata_other.io!=0x170 || ata_other.control!=0x376) return 75;
  scheduler.current->io_locks=0xFFFFFFFF;
  if(I386AtaChannelAcquire(&ata_channel) || ata_channel.owner) return 76;
  scheduler.current->io_locks=0;
  saved=GetRFlags; SetRFlags(saved|0x200);
  if(!I386AtaChannelAcquire(&ata_channel) || !I386AtaChannelAcquire(&ata_other) ||
      scheduler.current->io_locks!=2 || !(GetRFlags&0x200) ||
      !I386AtaChannelRelease(&ata_other) || scheduler.current->io_locks!=1 ||
      !I386AtaChannelRelease(&ata_channel) || scheduler.current->io_locks ||
      !I386AtaChannelClose(&ata_channel) || !I386AtaChannelClose(&ata_other) || !(GetRFlags&0x200)) return 77;
  SetRFlags(saved);
  return AtaCancelTest;
}
