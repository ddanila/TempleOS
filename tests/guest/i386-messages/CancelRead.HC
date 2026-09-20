CI386MsgQueue *cancel_queue;
CI386Task cancel_foreign;
U32 read_cancel_done,read_next_done,read_cancel_if;
U0 CancelReader(I64 unused)
{
  CI386Message message;
  CI386TaskWait guard;
  SetRFlags((GetRFlags&~0x200)|read_cancel_if);
  message.type=99; message.arg1=98; message.arg2=97;
  tasks[1].wait=&guard;
  if(I386MsgRead(cancel_queue,&message,1<<2) || tasks[1].wait!=&guard ||
      message.type!=99 || message.arg1!=98 || message.arg2!=97) errors++;
  tasks[1].wait=0;
  if(I386MsgRead(cancel_queue,&message,1<<2) || message.type!=99 ||
      message.arg1!=98 || message.arg2!=97 || tasks[1].wait || tasks[1].task_flags!=1<<31 ||
      (GetRFlags&0x200)!=read_cancel_if) errors++;
  read_cancel_done++;
}
U0 NextReader(I64 unused)
{
  CI386Message message;
  if(I386MsgRead(cancel_queue,&message,1<<2)!=2 || message.arg1!=42 ||
      message.arg2!=43 || tasks[2].task_flags) errors++;
  read_next_done++;
}
I64 CancelReadTest()
{
  CI386Heap heap;
  CI386Message message;
  Bool bound,accepted;
  U8 *reuse;
  I64 scenario,i;
  U32 saved=GetRFlags;
  if(!I386HeapInit(&heap,0x40000,8192)) return 60;
  for(scenario=0;scenario<6;scenario++) {
    read_cancel_done=0; read_next_done=0; read_cancel_if=(scenario&1)*0x200;
    bound=scenario==1 || scenario==3;
    SetRFlags((saved&~0x200)|read_cancel_if);
    cancel_queue=I386HeapAlloc(&heap,sizeof(CI386MsgQueue),TRUE);
    if(!cancel_queue || !I386MsgInit(cancel_queue,&scheduler) || cancel_queue->read_cancelled ||
        !I386ContextInit(&tasks[1].context,0x52000,8192,&CancelReader,0,&EndTask) ||
        !I386SchedAdd(&scheduler,&tasks[1])) return 61;
    tasks[1].task_flags=1<<31;
    if(bound && !I386MsgAttach(cancel_queue,&tasks[1])) return 62;
    if(!I386SchedYield(&scheduler) || read_cancel_done || !tasks[1].blocked ||
        cancel_queue->waiter!=&tasks[1] || !cancel_queue->read_cancelled ||
        *cancel_queue->read_cancelled || !tasks[1].wait || tasks[1].wait->kind!=I386_WAIT_MESSAGE ||
        tasks[1].wait->object!=cancel_queue || tasks[1].wait->cancelled || tasks[1].task_flags!=(1<<31|1<<TASKf_AWAITING_MSG)) return 63;
    if(I386MsgCancelRead(0,&tasks[1]) || I386MsgCancelRead(cancel_queue,0) ||
        I386MsgCancelRead(cancel_queue,&tasks[0]) || I386MsgCancelRead(cancel_queue,&cancel_foreign) ||
        !tasks[1].blocked || *cancel_queue->read_cancelled) return 64;
    tasks[1].task_flags|=1<<TASKf_SUSPENDED; tasks[1].wake_jiffy=0x100000001;
    if(scenario==1 && !I386SchedWake(&scheduler,&tasks[1])) return 65;
    if((scenario==2 || scenario==3) && !I386MsgSend(cancel_queue,2,42,43)) return 66;
    if(scenario==3 && !I386MsgClose(cancel_queue)) return 67;
    if(scenario&1) accepted=I386MsgCancelRead(cancel_queue,&tasks[1]);
    else accepted=I386TaskCancelWait(&tasks[1]);
    if(!accepted || !tasks[1].wait || !tasks[1].wait->cancelled ||
        I386TaskCancelWait(&tasks[1]) ||
        I386MsgCancelRead(cancel_queue,&tasks[1]) || cancel_queue->waiter ||
        cancel_queue->read_cancelled || tasks[1].blocked ||
        tasks[1].task_flags!=(1<<31|1<<TASKf_SUSPENDED) ||
        tasks[1].wake_jiffy!=0x100000001 || (GetRFlags&0x200)!=read_cancel_if ||
        cancel_queue->closed!=(scenario==3) ||
        cancel_queue->count!=((scenario==2 || scenario==3)!=0)) return 68;
    if(!I386SchedYield(&scheduler) || read_cancel_done || tasks[1].finished) return 69;
    if(scenario==2 && (I386MsgRead(cancel_queue,&message,1<<2,FALSE)!=2 ||
        message.arg1!=42 || message.arg2!=43 || cancel_queue->count)) return 70;
    if(scenario==4) {
      //The cancelled reader may no longer access the queue, even to unregister.
      if(!I386HeapFree(&heap,cancel_queue) ||
          !(reuse=I386HeapAlloc(&heap,sizeof(CI386MsgQueue))) || reuse!=(cancel_queue+0)(U8 *)) return 71;
      for(i=0;i<sizeof(CI386MsgQueue);i++) reuse[i]=0xA5;
    }
    if(scenario==5) {
      if(!I386ContextInit(&tasks[2].context,0x54000,8192,&NextReader,0,&EndTask) ||
          !I386SchedAdd(&scheduler,&tasks[2]) || !I386SchedYield(&scheduler) ||
          !tasks[2].blocked || cancel_queue->waiter!=&tasks[2] ||
          !cancel_queue->read_cancelled || *cancel_queue->read_cancelled || read_next_done) return 72;
    }
    if(I386TaskCancelWait(&tasks[1]) || !tasks[1].wait || !tasks[1].wait->cancelled) return 80;
    tasks[1].task_flags&=~(1<<TASKf_SUSPENDED); tasks[1].wake_jiffy=0;
    if(!I386SchedYield(&scheduler) || read_cancel_done!=1 || !tasks[1].finished || errors ||
        tasks[1].task_flags!=1<<31 || (GetRFlags&0x200)!=read_cancel_if) return 73;
    if(scenario==5) {
      if(!tasks[2].blocked || tasks[2].task_flags!=1<<TASKf_AWAITING_MSG ||
          cancel_queue->waiter!=&tasks[2] || !cancel_queue->read_cancelled ||
          *cancel_queue->read_cancelled || !I386MsgSend(cancel_queue,2,42,43) ||
          !I386SchedYield(&scheduler) || read_next_done!=1 || !tasks[2].finished ||
          errors || cancel_queue->waiter || cancel_queue->read_cancelled ||
          !I386SchedReap(&scheduler,&tasks[2])) return 74;
    }
    if(scenario==4) {
      for(i=0;i<sizeof(CI386MsgQueue);i++) if(reuse[i]!=0xA5) return 75;
    } else {
      if(cancel_queue->waiter || cancel_queue->read_cancelled) return 76;
      if(!cancel_queue->closed && !I386MsgClose(cancel_queue)) return 77;
      if(bound && (!I386MsgDetach(cancel_queue) || tasks[1].messages)) return 78;
    }
    if(!I386SchedReap(&scheduler,&tasks[1]) || !I386HeapFree(&heap,cancel_queue) ||
        heap.used || heap.allocations || !I386HeapValid(&heap)) return 79;
    tasks[1].task_flags=0;
  }
  SetRFlags(saved);
  return 0;
}
