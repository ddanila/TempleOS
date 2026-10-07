#ifndef I386_FRAME_INCLUDED
#define I386_FRAME_INCLUDED
#include "/Kernel/I386/Cpu.HH"
class CI386Frame
{
  CI386Frame *parent;
  U8 *return_address;
};
#assert sizeof(CI386Frame)==8
public extern Bool I386FrameValid(CI386Frame *frame,U8 *stack,I64 size);
public extern CI386Frame *I386FrameParent(CI386Frame *frame,U8 *stack,I64 size);
public extern U8 *I386FrameReturn(CI386Frame *frame,U8 *stack,I64 size);
#ifndef I386_SCHEDULER_INCLUDED
extern class CI386Task;
#endif
public extern Bool I386TaskFrameBounds(CI386Task *task,CI386Frame *frame,U8 **base,I64 *size);
public extern CI386Frame *I386TaskFrameParent(CI386Task *task,CI386Frame *frame);
public extern U8 *I386TaskFrameReturn(CI386Task *task,CI386Frame *frame);
#endif
