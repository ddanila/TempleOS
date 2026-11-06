Bool NativeTaskContextSpan(CI386Task *task,U8 *address,I64 bytes)
{//The switch frame may live on the ordinary or active debugger stack.
  U64 start=(address+0)(U64),base,end;
  I64 size;
  if(!address || start&3 || bytes<1 || bytes>0x100000000)return FALSE;
  base=(&task->stk->stk_base)(U64);size=task->stk->stk_size;
  end=base+size;
  if(size>=bytes && end<=0x100000000 && base<=start<=end-bytes)return TRUE;
  base=(task->debug_stack+0)(U64);size=task->debug_stack_size;
  end=base+size;
  return base && size>=bytes && end<=0x100000000 && base<=start<=end-bytes;
}
U8 *NativeTaskCaller(CTask *target=NULL,I64 num=0,Bool saved_context=FALSE)
{//Public CTask register shadows describe CPU stops, not scheduler switches.
  CI386Task *task=target;
  CI386Frame *frame;
  U32 *context,irq;
  U8 *result=0;
  if(!task)task=I386TaskSelf;
  if(num<0)return 0;
  if(!saved_context && task==I386TaskSelf)return NativeCaller(num+1);
  irq=I386IrqSave;
  if(!TaskValidate(task) || !task->stk ||
      num>task->stk->stk_size/sizeof(CI386Frame))goto done;
  if(task->debug_cpu_active) {
    if(task->rip>U32_MAX || task->rbp>U32_MAX)goto done;
    if(!num) {result=task->rip;goto done;}
    frame=task->rbp;
  } else {
    context=task->context.esp;
    //TaskContext.HC saves GS,FS,ES,DS,PUSHAD,EFLAGS and the return address.
    //Context.HC constructs the same frame for a not-yet-started task.
    if(!NativeTaskContextSpan(task,context,14*sizeof(U32)))goto done;
    if(!num) {result=context[13];goto done;}
    frame=context[6];
  }
  while(num) {
    if(!--num) {result=I386TaskFrameReturn(task,frame);goto done;}
    frame=I386TaskFrameParent(task,frame);
    if(!frame)goto done;
  }
done:
  I386IrqRestore(irq);return result;
}
