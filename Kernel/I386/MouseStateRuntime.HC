//Logical mouse state is updated in scheduled context, never from IRQ12.
CMsStateGlbls ms;
CGridGlbls ms_grid;
#include "/Kernel/KeyboardStateTypes.HH"
CKbdStateGlbls native_keyboard;
class CNativeInputMouse { I64 timestamp; };
CNativeInputMouse native_input_mouse;
F64 (*native_mouse_trunc)(F64 value);
F64 NativeMouseTrunc(F64 value) { return (*native_mouse_trunc)(value); }
#define kbd native_keyboard
#define ms_hard native_input_mouse
#include "/Kernel/KbdMsEventTimeCore.HC"
#define Trunc NativeMouseTrunc
#include "/Kernel/MouseUpdateCore.HC"
#include "/Kernel/MouseHardPositionCore.HC"
U32 native_mouse_serial,native_mouse_packet_losses;
Bool native_mouse_synchronized;
I64 native_mouse_last_x,native_mouse_last_y,native_mouse_last_stamp;
CD3 native_mouse_hard_scale;
CD3I64 native_mouse_hard_prescale,native_mouse_hard_position;
U32 native_mouse_hard_buttons,native_mouse_start_buttons;
I64 native_mouse_start_x,native_mouse_start_y;
//IRQ input is integer-only and unbounded; apply original scaling/clipping later.
#define MOUSE_FEED_FUNCTION NativeMouseIRQDecode
#define MOUSE_FEED_UNBOUNDED
#include "/Kernel/I386/MouseFeedCore.HC"
#include "/Kernel/I386/MouseEventQueue.HC"
CI386MouseState native_mouse_irq_state;
CI386MouseEvents native_mouse_packets,native_mouse_events;
I64 native_mouse_irq_z,native_mouse_packet_z[64];
Bool native_mouse_set_pending;
CD3I64 native_mouse_set_prescale;
U32 native_mouse_set_buttons;
I64 native_mouse_set_stamp;
class CNativeMousePosition {CD3I64 pos,presnap;};
CNativeMousePosition native_mouse_positions[64];
U0 NativeMouseDecoderInit()
{//Caller excludes IRQs. Console initialization precedes hardware setup.
  if(!native_mouse_irq_state.installed && console_config && console_config->mouse &&
      console_config->mouse->installed) {
    MemCpy(&native_mouse_irq_state,console_config->mouse,sizeof(CI386MouseState));
    native_mouse_irq_state.x*=2;native_mouse_irq_state.y*=2;
    native_mouse_start_x=native_mouse_irq_state.x;native_mouse_start_y=native_mouse_irq_state.y;
    native_mouse_start_buttons=native_mouse_irq_state.buttons;
  }
}
U0 NativeMouseIRQ(U8 data,U8 status)
{
  NativeMouseDecoderInit;
  if(!NativeMouseIRQDecode(&native_mouse_irq_state,data,status) || native_mouse_irq_state.count)return;
  if(native_mouse_irq_state.packet_size==4) {
    if(native_mouse_irq_state.fourth&8)native_mouse_irq_z+=(native_mouse_irq_state.fourth&7)-8;
    else native_mouse_irq_z+=native_mouse_irq_state.fourth&7;
  }
  //Offset adjustment depends on the path at edges; do not coalesce raw packets.
  I386MouseEventPush(&native_mouse_packets,native_mouse_irq_state.x,
    native_mouse_irq_state.y,native_mouse_irq_state.buttons,NativeTimeStamp,FALSE);
  native_mouse_packet_z[(native_mouse_packets.write+63)&63]=native_mouse_irq_z;
}
U0 NativeMouseLogicalQueue(I64 stamp,U32 buttons)
{
  U32 slot;
  I386MouseEventPush(&native_mouse_events,ms.pos.x,ms.pos.y,buttons,stamp);
  slot=(native_mouse_events.write+63)&63;
  MemCpy(&native_mouse_positions[slot].pos,&ms.pos,sizeof(CD3I64));
  MemCpy(&native_mouse_positions[slot].presnap,&ms.presnap,sizeof(CD3I64));
}
Bool NativeMouseEventRead(CI386MouseEvent *event,CNativeMousePosition *position)
{
  U32 irq=I386IrqSave,slot=native_mouse_events.read;
  Bool result=I386MouseEventPop(&native_mouse_events,event);
  if(result)MemCpy(position,&native_mouse_positions[slot],sizeof(CNativeMousePosition));
  I386IrqRestore(irq);return result;
}
U0 NativeMouseStateInit()
{
  ms.scale.x=ms.scale.y=ms.scale.z=1.0;
  native_mouse_hard_scale.x=native_mouse_hard_scale.y=0.5;native_mouse_hard_scale.z=1.0;
  ms.dbl_time=0.350;ms.show=TRUE;
  ms.timestamp=NativeTimeStamp;native_input_mouse.timestamp=ms.timestamp;
  native_mouse_last_stamp=ms.timestamp;GridInit;
}
U0 NativeMouseApply(I64 x,I64 y,I64 z,U32 buttons,I64 stamp,Bool publish)
{
  I64 old_x=native_mouse_hard_position.x,old_y=native_mouse_hard_position.y,old_z=native_mouse_hard_position.z;
  I64 delta=stamp-native_mouse_last_stamp,dx,dy;
  native_mouse_hard_prescale.x=x;native_mouse_hard_prescale.y=y;native_mouse_hard_prescale.z=z;
  MouseHardPositionCore(&native_mouse_hard_prescale,&native_mouse_hard_scale,
    &native_mouse_hard_position,&ms,&ms_grid);
  x=native_mouse_hard_position.x;y=native_mouse_hard_position.y;
  if(!native_mouse_synchronized || x!=old_x || y!=old_y || native_mouse_hard_position.z!=old_z || buttons!=native_mouse_hard_buttons) {
    dx=x-native_mouse_last_x;dy=y-native_mouse_last_y;
    if(native_mouse_synchronized && (dx || dy) && delta>0)
      ms.speed=Sqrt(SqrI64(dx)+SqrI64(dy))*1193182.0/delta;
    native_mouse_last_x=x;native_mouse_last_y=y;native_mouse_last_stamp=stamp;
    ms.timestamp=stamp;MsUpdate(x,y,native_mouse_hard_position.z,(buttons&1)!=0,(buttons&2)!=0);
    native_mouse_hard_buttons=buttons;
    if(publish)NativeMouseLogicalQueue(stamp,buttons);
  }
}
U0 NativeMouseSync()
{//Scheduled only. Preserve all packet path effects before coalescing UI motion.
  CI386MouseEvent event;
  U32 irq,slot;
  if(!console_config || !console_config->mouse || !console_config->mouse->installed)return;
  irq=I386IrqSave;NativeMouseDecoderInit;
  ms.has_wheel=(native_mouse_irq_state.protocol_flags&1)!=0;
  if(!native_mouse_synchronized) {
    NativeMouseApply(native_mouse_start_x,native_mouse_start_y,0,
      native_mouse_start_buttons,NativeTimeStamp,TRUE);
    native_mouse_synchronized=TRUE;
  }
  if(native_mouse_packet_losses!=native_mouse_packets.losses) {
    native_mouse_packet_losses=native_mouse_packets.losses;
    native_mouse_events.read=native_mouse_events.write=native_mouse_events.count=0;
    native_mouse_events.losses++;
  }
  if(native_mouse_set_pending) {
    native_mouse_set_pending=FALSE;
    NativeMouseApply(native_mouse_set_prescale.x,native_mouse_set_prescale.y,
      native_mouse_set_prescale.z,native_mouse_set_buttons,native_mouse_set_stamp,TRUE);
  }
  while(native_mouse_packets.count) {
    slot=native_mouse_packets.read;
    if(!I386MouseEventPop(&native_mouse_packets,&event))break;
    NativeMouseApply(event.x,event.y,native_mouse_packet_z[slot],event.buttons,event.stamp,TRUE);
  }
  native_mouse_serial=native_mouse_irq_state.serial;
  I386IrqRestore(irq);
}
Bool NativeLogicalMouseGet(I64 *x,I64 *y,I64 *buttons=0,I64 *packets=0)
{
  U32 irq;
  if(!x || !y || !console_config || !console_config->mouse || !console_config->mouse->installed)return FALSE;
  NativeMouseSync;irq=I386IrqSave;*x=ms.pos.x;*y=ms.pos.y;
  if(buttons)*buttons=ms.lb+2*ms.rb;
  if(packets)*packets=console_config->mouse->packets;
  I386IrqRestore(irq);return TRUE;
}

U0 MsHardSet(I64 x,I64 y,I64 z,I64 l,I64 r)
{//MsSet holds the IRQ lock. Pending physical deltas remain after the new base.
  CD3I64 prescale,position,previous;
  I64 dx,dy,dz;
  U32 slot,remaining;
  NativeMouseDecoderInit;
  MemCpy(&previous,&native_mouse_hard_prescale,sizeof(CD3I64));
  if(native_mouse_set_pending)MemCpy(&previous,&native_mouse_set_prescale,sizeof(CD3I64));
  prescale.x=x/native_mouse_hard_scale.x/ms_grid.x_speed;
  prescale.y=y/native_mouse_hard_scale.y/ms_grid.y_speed;
  prescale.z=z/native_mouse_hard_scale.z/ms_grid.z_speed;
  dx=prescale.x-previous.x;dy=prescale.y-previous.y;dz=prescale.z-previous.z;
  native_mouse_irq_state.x+=dx;native_mouse_irq_state.y+=dy;native_mouse_irq_z+=dz;
  slot=native_mouse_packets.read;remaining=native_mouse_packets.count;
  while(remaining) {
    native_mouse_packets.events[slot].x+=dx;native_mouse_packets.events[slot].y+=dy;
    native_mouse_packet_z[slot]+=dz;slot=(slot+1)&63;remaining--;
  }
  native_mouse_irq_state.buttons=(native_mouse_irq_state.buttons&4)|l|(r<<1);
  MemCpy(&native_mouse_set_prescale,&prescale,sizeof(CD3I64));
  native_mouse_set_buttons=native_mouse_irq_state.buttons;
  native_mouse_set_stamp=native_input_mouse.timestamp=NativeTimeStamp;
  native_mouse_set_pending=TRUE;
  MouseHardPositionCore(&prescale,&native_mouse_hard_scale,&position,&ms,&ms_grid);
}
#define MOUSE_SET_FUNCTION NativeMouseSetCore
#include "/Kernel/MouseSetCore.HC"
U0 MsSet(I64 x=I64_MAX,I64 y=I64_MAX,I64 z=I64_MAX,I64 l=I64_MAX,I64 r=I64_MAX)
{
  U32 irq=I386IrqSave;
  NativeMouseSetCore(x,y,z,l,r);
  I386IrqRestore(irq);
}
