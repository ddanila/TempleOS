#ifndef I386_TASK_PLATFORM_INCLUDED
#define I386_TASK_PLATFORM_INCLUDED
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Gdt.HH"
#include "/Kernel/I386/Frame.HH"
#include "/Kernel/I386/Cpu.HH"
//Single CPU, once only, IF clear. Records/table/stack/heap remain live.
public extern Bool I386TaskPlatformInit(CI386Scheduler *s,CI386Task *root,
  CI386Cpu *cpu,U8 *gdt,U8 *stack,I64 stack_size,CI386Heap *heap);
#endif
