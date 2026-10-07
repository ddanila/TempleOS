#include "/Kernel/I386/Frame.HH"
Bool I386FrameValid(CI386Frame *frame,U8 *stack,I64 size)
{
  U64 address=(frame+0)(U64),base=(stack+0)(U64),end;
  if(!frame || !stack || size<8 || size>0x100000000 || address&3) return FALSE;
  end=base+size;
  if(end>0x100000000 || address<base || address>end-8) return FALSE;
  return TRUE;
}
CI386Frame *I386FrameParent(CI386Frame *frame,U8 *stack,I64 size)
{
  CI386Frame *parent;
  if(!I386FrameValid(frame,stack,size)) return 0;
  parent=frame->parent;
  //Stacks grow down; parents must follow the complete header, rejecting cycles.
  if((parent+0)(U64)<(frame+0)(U64)+sizeof(CI386Frame) ||
      !I386FrameValid(parent,stack,size)) return 0;
  return parent;
}
U8 *I386FrameReturn(CI386Frame *frame,U8 *stack,I64 size)
{
  if(!I386FrameValid(frame,stack,size)) return 0;
  return frame->return_address;
}

#include "/Kernel/I386/Task.HH"
Bool I386TaskFrameBounds(CI386Task *task,CI386Frame *frame,U8 **base,I64 *size)
{
  U8 *region;
  I64 bytes;
  if(!task || !task->stk || !base || !size) return FALSE;
  region=(&task->stk->stk_base)(U8 *);bytes=task->stk->stk_size;
  if(I386FrameValid(frame,region,bytes)) {*base=region;*size=bytes;return TRUE;}
  region=task->debug_stack;bytes=task->debug_stack_size;
  if(!region || !bytes || I386HeapSize(task->debug_stack_heap,region)!=bytes ||
      !I386FrameValid(frame,region,bytes)) return FALSE;
  *base=region;*size=bytes;return TRUE;
}
CI386Frame *I386TaskFrameParent(CI386Task *task,CI386Frame *frame)
{
  CI386Frame *parent;
  U8 *base,*parent_base;
  I64 size,parent_size;
  if(!I386TaskFrameBounds(task,frame,&base,&size)) return 0;
  parent=frame->parent;
  if(!I386TaskFrameBounds(task,parent,&parent_base,&parent_size)) return 0;
  if(base==parent_base) {
    if((parent+0)(U64)<(frame+0)(U64)+sizeof(CI386Frame)) return 0;
  } else if(base!=task->debug_stack || parent_base!=(&task->stk->stk_base)(U8 *)) return 0;
  return parent;
}
U8 *I386TaskFrameReturn(CI386Task *task,CI386Frame *frame)
{
  U8 *base;
  I64 size;
  if(!I386TaskFrameBounds(task,frame,&base,&size)) return 0;
  return frame->return_address;
}
