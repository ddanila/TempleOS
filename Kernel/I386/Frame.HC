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
