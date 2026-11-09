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
U32 native_mouse_serial;
Bool native_mouse_synchronized;
I64 native_mouse_last_x,native_mouse_last_y,native_mouse_last_stamp;
//IRQ storage retains button transitions; logical state remains scheduled-only.
#define MOUSE_FEED_FUNCTION NativeMouseIRQDecode
#include "/Kernel/I386/MouseFeedCore.HC"
#include "/Kernel/I386/MouseEventQueue.HC"
CI386MouseState native_mouse_irq_state;
CI386MouseEvents native_mouse_events;
U0 NativeMouseIRQ(U8 data,U8 status)
{
  //Console initialization precedes PS/2 setup; seed from the installed hardware.
  if(!native_mouse_irq_state.installed) {
    if(!console_config || !console_config->mouse || !console_config->mouse->installed)return;
    MemCpy(&native_mouse_irq_state,console_config->mouse,sizeof(CI386MouseState));
  }
  if(!NativeMouseIRQDecode(&native_mouse_irq_state,data,status) || native_mouse_irq_state.count)return;
  I386MouseEventPush(&native_mouse_events,native_mouse_irq_state.x,
    native_mouse_irq_state.y,native_mouse_irq_state.buttons,NativeTimeStamp);
}
Bool NativeMouseEventRead(CI386MouseEvent *event)
{
  U32 irq=I386IrqSave;
  Bool result=I386MouseEventPop(&native_mouse_events,event);
  I386IrqRestore(irq);return result;
}
U0 NativeMouseStateInit()
{
  ms.scale.x=ms.scale.y=ms.scale.z=1.0;
  ms.dbl_time=0.350; ms.show=TRUE;
  ms.timestamp=NativeTimeStamp;
  native_input_mouse.timestamp=ms.timestamp;
  native_mouse_last_stamp=ms.timestamp;
  if(console_config->mouse) {
    MemCpy(&native_mouse_irq_state,console_config->mouse,sizeof(CI386MouseState));
    native_mouse_last_x=console_config->mouse->x;
    native_mouse_last_y=console_config->mouse->y;
  }
  GridInit;
}
U0 NativeMouseSync()
{//Coalesce completed hardware packets like the original hard-state event flag.
  CI386MouseState *mouse;
  U32 irq,serial,buttons;
  I64 x,y,stamp,delta,dx,dy;
  if(!console_config || !(mouse=console_config->mouse) || !mouse->installed)return;
  irq=I386IrqSave;
  serial=mouse->serial;
  if(!native_mouse_synchronized || serial!=native_mouse_serial) {
    x=mouse->x;y=mouse->y;buttons=mouse->buttons;
    stamp=NativeTimeStamp;delta=stamp-native_mouse_last_stamp;
    dx=x-native_mouse_last_x;dy=y-native_mouse_last_y;
    if(native_mouse_synchronized && (dx || dy) && delta>0)
      ms.speed=Sqrt(SqrI64(dx)+SqrI64(dy))*1193182.0/delta;
    native_mouse_last_x=x;native_mouse_last_y=y;native_mouse_last_stamp=stamp;
    ms.timestamp=stamp;
    MsUpdate(x,y,0,(buttons&1)!=0,(buttons&2)!=0);
    native_mouse_serial=serial;native_mouse_synchronized=TRUE;
  }
  I386IrqRestore(irq);
}
