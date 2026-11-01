//Logical mouse state is updated in scheduled context, never from IRQ12.
CMsStateGlbls ms;
CGridGlbls ms_grid;
class CNativeMouseKeyboard { I64 scan_code; };
CNativeMouseKeyboard native_mouse_keyboard;
F64 (*native_mouse_trunc)(F64 value);
F64 NativeMouseTrunc(F64 value) { return (*native_mouse_trunc)(value); }
#define kbd native_mouse_keyboard
#define Trunc NativeMouseTrunc
#include "/Kernel/MouseUpdateCore.HC"
U32 native_mouse_serial;
I64 native_mouse_last_x,native_mouse_last_y,native_mouse_last_stamp;
U0 NativeMouseStateInit()
{
  ms.scale.x=ms.scale.y=ms.scale.z=1.0;
  ms.dbl_time=0.350; ms.show=TRUE;
  ms.timestamp=NativeTimeStamp;
  native_mouse_last_stamp=ms.timestamp;
  if(console_config->mouse) {
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
  if(serial!=native_mouse_serial) {
    x=mouse->x;y=mouse->y;buttons=mouse->buttons;
    stamp=NativeTimeStamp;delta=stamp-native_mouse_last_stamp;
    dx=x-native_mouse_last_x;dy=y-native_mouse_last_y;
    if((dx || dy) && delta>0)
      ms.speed=Sqrt(SqrI64(dx)+SqrI64(dy))*1193182.0/delta;
    native_mouse_last_x=x;native_mouse_last_y=y;native_mouse_last_stamp=stamp;
    ms.timestamp=stamp;
    MsUpdate(x,y,0,(buttons&1)!=0,(buttons&2)!=0);
    native_mouse_serial=serial;
  }
  I386IrqRestore(irq);
}
