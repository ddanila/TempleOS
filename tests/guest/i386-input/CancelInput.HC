CI386KbcInput *cancel_stream;
CI386KeyboardReader cancel_decoder;
CI386Task cancel_foreign;
U32 cancel_input_done,cancel_next_done,cancel_input_if;
U0 CancelInputWorker(I64 decoded)
{
  U8 data=0x55,status=0xAA;
  CI386KeyEvent event;
  CI386TaskWait guard;
  SetRFlags((GetRFlags&~0x200)|cancel_input_if);
  tasks[1].wait=&guard;
  if(I386KbcInputRead(cancel_stream,&data,&status) || tasks[1].wait!=&guard ||
      data!=0x55 || status!=0xAA) errors++;
  tasks[1].wait=0;
  if(decoded) {
    event.type=99; event.ch=98; event.scan=97;
    if(I386KeyboardRead(&cancel_decoder,&event) || event.type!=99 || event.ch!=98 || event.scan!=97) errors++;
  } else if(I386KbcInputRead(cancel_stream,&data,&status) || data!=0x55 || status!=0xAA) errors++;
  if(tasks[1].wait || tasks[1].task_flags!=1<<31 || (GetRFlags&0x200)!=cancel_input_if) errors++;
  cancel_input_done++;
}
U0 CancelInputNext(I64 unused)
{
  U8 data,status;
  if(!I386KbcInputRead(cancel_stream,&data,&status) || data!=0x1E || status!=1) errors++;
  cancel_next_done++;
}
I64 CancelInputTest()
{
  CI386Heap heap;
  CI386KeyEvent event;
  U8 data,status,*reuse;
  U32 saved=GetRFlags;
  I64 scenario,i;
  Bool accepted;
  if(!I386HeapInit(&heap,0x40000,8192)) return 210;
  for(scenario=0;scenario<6;scenario++) {
    cancel_input_done=0; cancel_next_done=0; cancel_input_if=(scenario&1)*0x200;
    SetRFlags((saved&~0x200)|cancel_input_if);
    cancel_stream=I386HeapAlloc(&heap,sizeof(CI386KbcInput),TRUE);
    if(!cancel_stream || !I386KbcInputInit(cancel_stream,&scheduler) || cancel_stream->read_cancelled ||
        !I386ContextInit(&tasks[1].context,0x52000,8192,&CancelInputWorker,scenario==5,&EndTask) ||
        !I386SchedAdd(&scheduler,&tasks[1])) return 211;
    tasks[1].task_flags=1<<31;
    if(scenario==5) {
      cancel_decoder.input=0;
      if(!I386KeyboardReadInit(&cancel_decoder,cancel_stream) || !I386KbcInputPut(cancel_stream,0xE0,1)) return 212;
    }
    if(!I386SchedYield(&scheduler) || !tasks[1].blocked || cancel_stream->waiter!=&tasks[1] ||
        !cancel_stream->read_cancelled || *cancel_stream->read_cancelled || cancel_input_done ||
        !tasks[1].wait || tasks[1].wait->kind!=I386_WAIT_KEYBOARD ||
        tasks[1].wait->object!=cancel_stream || tasks[1].wait->cancelled) return 213;
    if(I386KbcInputCancel(0,&tasks[1]) || I386KbcInputCancel(cancel_stream,0) ||
        I386KbcInputCancel(cancel_stream,&tasks[0]) || I386KbcInputCancel(cancel_stream,&cancel_foreign) ||
        !tasks[1].blocked || *cancel_stream->read_cancelled) return 214;
    tasks[1].task_flags|=1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG;
    tasks[1].wake_jiffy=0x100000001;
    if(scenario==1 && !I386SchedWake(&scheduler,&tasks[1])) return 215;
    if(scenario==2 && (!I386KbcInputPut(cancel_stream,0x1E,0x81) ||
        !I386KbcInputPut(cancel_stream,0x9E,1))) return 216;
    if(scenario&1) accepted=I386KbcInputCancel(cancel_stream,&tasks[1]);
    else accepted=I386TaskCancelWait(&tasks[1]);
    if(!accepted || !tasks[1].wait || !tasks[1].wait->cancelled ||
        I386TaskCancelWait(&tasks[1]) || I386KbcInputCancel(cancel_stream,&tasks[1]) ||
        tasks[1].blocked || cancel_stream->waiter || cancel_stream->read_cancelled ||
        tasks[1].task_flags!=(1<<31|1<<TASKf_SUSPENDED|1<<TASKf_AWAITING_MSG) ||
        tasks[1].wake_jiffy!=0x100000001 || (GetRFlags&0x200)!=cancel_input_if ||
        cancel_stream->queue.dropped || !I386SchedYield(&scheduler) || cancel_input_done) return 217;
    if(scenario==2 && (cancel_stream->queue.count!=2 ||
        !I386KbcInputRead(cancel_stream,&data,&status,FALSE) || data!=0x1E || status!=0x81 ||
        !I386KbcInputRead(cancel_stream,&data,&status,FALSE) || data!=0x9E || status!=1)) return 218;
    if(scenario==3) {
      if(!I386HeapFree(&heap,cancel_stream) || !(reuse=I386HeapAlloc(&heap,sizeof(CI386KbcInput))) ||
          reuse!=(cancel_stream+0)(U8 *)) return 219;
      for(i=0;i<sizeof(CI386KbcInput);i++) reuse[i]=0xA5;
    }
    if(scenario==4 && (!I386ContextInit(&tasks[2].context,0x54000,8192,&CancelInputNext,0,&EndTask) ||
        !I386SchedAdd(&scheduler,&tasks[2]) || !I386SchedYield(&scheduler) || !tasks[2].blocked ||
        cancel_stream->waiter!=&tasks[2] || !cancel_stream->read_cancelled ||
        *cancel_stream->read_cancelled || cancel_next_done)) return 220;
    if(I386TaskCancelWait(&tasks[1]) || !tasks[1].wait || !tasks[1].wait->cancelled) return 227;
    tasks[1].task_flags=1<<31; tasks[1].wake_jiffy=0;
    if(!I386SchedYield(&scheduler) || cancel_input_done!=1 || !tasks[1].finished || errors ||
        (GetRFlags&0x200)!=cancel_input_if) return 221;
    if(scenario==4 && (!tasks[2].blocked || cancel_stream->waiter!=&tasks[2] ||
        !cancel_stream->read_cancelled || *cancel_stream->read_cancelled ||
        !I386KbcInputPut(cancel_stream,0x1E,1) || !I386SchedYield(&scheduler) || cancel_next_done!=1 ||
        !tasks[2].finished || errors || !I386SchedReap(&scheduler,&tasks[2]))) return 222;
    if(scenario==5 && (!cancel_decoder.state.packet.extended ||
        !I386KbcInputPut(cancel_stream,0x48,1) || I386KeyboardRead(&cancel_decoder,&event,FALSE)!=1 ||
        (event.scan&0x1FF)!=0x48 || ((event.scan>>32)&0x1FF)!=0xC8 || cancel_decoder.state.packet.extended)) return 223;
    if(scenario==3) {
      for(i=0;i<sizeof(CI386KbcInput);i++) if(reuse[i]!=0xA5) return 224;
    } else if(cancel_stream->waiter || cancel_stream->read_cancelled || cancel_stream->queue.count) return 225;
    if(!I386SchedReap(&scheduler,&tasks[1]) || !I386HeapFree(&heap,cancel_stream) ||
        heap.used || heap.allocations || !I386HeapValid(&heap)) return 226;
    tasks[1].task_flags=0;
  }
  SetRFlags(saved);
  return 0;
}
