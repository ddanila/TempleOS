U32 cancel_mask,cancel_order,cancel_done,cancel_if;
U0 AtaCancelWorker(I64 id)
{
  Bool acquired;
  SetRFlags((GetRFlags&~0x200)|cancel_if);
  acquired=I386AtaChannelAcquire(&ata_channel);
  if((GetRFlags&0x200)!=cancel_if) errors++;
  if(cancel_mask & (1<<id)) {
    if(acquired || I386TaskSelf->io_locks) errors++;
  } else {
    if(!acquired || ata_channel.owner!=I386TaskSelf || I386TaskSelf->io_locks!=1) errors++;
    cancel_order=cancel_order*10+id+1;
    if(!I386AtaChannelRelease(&ata_channel)) errors++;
  }
  cancel_done++;
}
I64 AtaCancelTest()
{
  CI386Heap heap;
  CI386AtaWaiter *node;
  CI386Task *owner;
  I64 scenario,i,expected,seen,cancel_count;
  U32 saved=GetRFlags;
  if(!I386HeapInit(&heap,0x60000,32768)) return 150;
  for(scenario=0;scenario<6;scenario++) {
    cancel_mask=2; expected=13;
    if(scenario==1) { cancel_mask=4; expected=12; }
    if(scenario==2) { cancel_mask=1; expected=23; }
    if(scenario==3 || scenario==5) { cancel_mask=7; expected=0; }
    cancel_order=0; cancel_done=0; cancel_count=0; cancel_if=(scenario&1)*0x200;
    SetRFlags((saved&~0x200)|cancel_if);
    if(!I386AtaChannelInit(&ata_channel,&scheduler,0) || !I386AtaChannelAcquire(&ata_channel)) return 151;
    for(i=0;i<3;i++) {
      ata_tasks[i]=I386TaskSpawn(&scheduler,&heap,8192,&AtaCancelWorker,i);
      if(!ata_tasks[i]) return 152;
    }
    if(!I386SchedYield(&scheduler) || cancel_done || cancel_order) return 153;
    for(i=0;i<3;i++) if(!ata_tasks[i]->task.blocked) return 154;
    if(scenario==4) {
      //Release has already granted the first worker ownership, before it runs.
      if(!I386AtaChannelRelease(&ata_channel) || ata_channel.owner!=&ata_tasks[0]->task ||
          ata_tasks[0]->task.io_locks!=1) return 155;
    }
    owner=ata_channel.owner;
    if(I386AtaChannelCancelWait(0,owner) || I386AtaChannelCancelWait(&ata_channel,0) ||
        I386AtaChannelCancelWait(&ata_channel,&foreign_task) ||
        I386AtaChannelCancelWait(&ata_channel,owner)) return 156;
    if(scenario==5) ata_channel.poisoned=TRUE;
    for(i=0;i<3;i++) if(cancel_mask & (1<<i)) {
      //A spurious private wake and public suspension must both survive safely.
      cancel_count++;
      if((scenario&1) && !I386SchedWake(&scheduler,&ata_tasks[i]->task)) return 157;
      ata_tasks[i]->task.task_flags|=1<<TASKf_SUSPENDED;
      ata_tasks[i]->task.wake_jiffy=0x100000001;
      if(!I386AtaChannelCancelWait(&ata_channel,&ata_tasks[i]->task) ||
          I386AtaChannelCancelWait(&ata_channel,&ata_tasks[i]->task) ||
          ata_tasks[i]->task.blocked || ata_tasks[i]->task.io_locks ||
          !(ata_tasks[i]->task.task_flags & (1<<TASKf_SUSPENDED)) ||
          ata_tasks[i]->task.wake_jiffy!=0x100000001 ||
          ata_channel.owner!=owner || owner->io_locks!=1 ||
          (GetRFlags&0x200)!=cancel_if) return 158;
    }
    node=ata_channel.head; seen=0;
    for(i=0;i<3;i++) if(!(cancel_mask & (1<<i)) && !(scenario==4 && i==0)) {
      if(!node || node->task!=&ata_tasks[i]->task || !node->queued) return 159;
      if(!node->next && ata_channel.tail!=node) return 160;
      node=node->next; seen++;
    }
    if(node || (!seen && ata_channel.tail)) return 161;
    if(scenario!=4 && !I386AtaChannelRelease(&ata_channel)) return 162;
    if(!I386SchedYield(&scheduler) || errors || cancel_done!=3-cancel_count) return 163;
    for(i=0;i<3;i++) if(cancel_mask & (1<<i)) {
      if(ata_tasks[i]->task.finished) return 164;
      ata_tasks[i]->task.task_flags&=~(1<<TASKf_SUSPENDED);
      ata_tasks[i]->task.wake_jiffy=0;
    }
    if(!I386SchedYield(&scheduler) || errors || cancel_done!=3 || cancel_order!=expected ||
        ata_channel.head || ata_channel.tail || ata_channel.owner || tasks[0].io_locks) return 165;
    for(i=0;i<3;i++) if(!ata_tasks[i]->task.finished || !I386TaskDestroy(ata_tasks[i])) return 166;
    if(heap.used || heap.allocations || !I386HeapValid(&heap)) return 167;
    //Only the test fixture clears injected poison after every waiter has left.
    ata_channel.poisoned=FALSE;
    if(!I386AtaChannelClose(&ata_channel) || (GetRFlags&0x200)!=cancel_if) return 168;
  }
  SetRFlags(saved);
  return 0;
}
