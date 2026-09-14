import U0 i386_context_switch(CI386Context *old,CI386Context *next);
import U0 i386_segments_reload(U16 fs,U16 gs);
CI386Scheduler *i386_platform_scheduler;
U8 *i386_platform_gdt;
U0 I386TaskPlatformStop()
{
  asm { CLI }
  while(1) { asm { HLT } }
}
U0 I386TaskPlatformBind(CI386Task *task)
{//Scheduler changes current with IRQs masked, then reloads before switching.
  if(!i386_platform_scheduler || (GetRFlags&0x200) || !task ||
      task->owner!=i386_platform_scheduler ||
      i386_platform_scheduler->current!=task ||
      !I386DataSegment(i386_platform_gdt+24,task,sizeof(CI386Task)))
    I386TaskPlatformStop;
  i386_segments_reload(0x18,0x20);
}
public Bool I386TaskPlatformInit(CI386Scheduler *s,CI386Task *root,
  CI386Cpu *cpu,U8 *gdt,U8 *stack,I64 stack_size,CI386Heap *heap)
{
  if(i386_platform_scheduler || (GetRFlags&0x200) || !s || !root || !cpu ||
      !gdt || !heap || (s+0)(U64)+sizeof(CI386Scheduler)>0x100000000 ||
      (root+0)(U64)+sizeof(CI386Task)>0x100000000 ||
      (cpu+0)(U64)+sizeof(CI386Cpu)>0x100000000 ||
      (gdt+0)(U64)+40>0x100000000 ||
      (heap+0)(U64)+sizeof(CI386Heap)>0x100000000 ||
      !stack || ((stack+0)(U64)&7) || stack_size<256 || stack_size>0xFFFFFFFF ||
      (stack_size&7) || !I386FrameValid(GetRBP,stack,stack_size)) return 0;
  if(s->root || root->owner || root->except_top || cpu->scheduler ||
      !I386HeapValid(heap)) return 0;
  //All recoverable validation precedes scheduler/table mutation.
  if(!I386SchedInit(s,root,&i386_context_switch)) return 0;
  root->stack_base=stack; root->stack_size=stack_size; root->memory=heap;
  cpu->addr=cpu; cpu->scheduler=s;
  if(!I386GdtInit(gdt,root,sizeof(CI386Task),cpu,sizeof(CI386Cpu))) I386TaskPlatformStop;
  i386_platform_gdt=gdt; i386_platform_scheduler=s;
  if(!I386GdtLoad(gdt,5) || !I386SchedSetBind(s,&I386TaskPlatformBind)) I386TaskPlatformStop;
  return 1;
}
