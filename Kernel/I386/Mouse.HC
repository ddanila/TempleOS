#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/Mouse.HH"
Bool I386MouseCommand(U8 value,I64 polls)
{
  U8 reply,status;
  if(!I386KbcWrite(TRUE,0xD4,polls) || !I386KbcWrite(FALSE,value,polls) ||
      !I386KbcReadWait(&reply,&status,polls)) return FALSE;
  return status&0x20 && !(status&0xC0) && reply==0xFA;
}
Bool I386MouseType(CI386MouseState *mouse,I64 polls)
{
  U8 kind,status;
  if(!I386MouseCommand(0xF2,polls) || !I386KbcReadWait(&kind,&status,polls) ||
      !(status&0x20) || status&0xC0)return FALSE;
  if(kind==3)mouse->protocol_flags|=1;
  if(kind==4)mouse->protocol_flags|=2;
  return kind==0 || kind==3 || kind==4;
}
public Bool I386MouseSetup(CI386MouseState *mouse,I64 polls=100000)
{//Boot-only exclusive 8042 ownership, IF clear and IRQ1/12 masked.
  U8 config,status;
  Bool result=FALSE;
  if(!mouse || polls<1 || polls>100000)return FALSE;
  mouse->installed=FALSE;mouse->packet_size=3;mouse->protocol_flags=0;mouse->fourth=0;
  if(!I386KbcWrite(TRUE,0xAD,polls))return FALSE;
  if(!I386KbcDrain(polls) || !I386KbcWrite(TRUE,0xA8,polls) ||
      !I386KbcWrite(TRUE,0x20,polls) || !I386KbcReadWait(&config,&status,polls) ||
      status&0xE0)goto mouse_setup_done;
  config=(config|3)&~0x20;
  if(!I386KbcWrite(TRUE,0x60,polls) || !I386KbcWrite(FALSE,config,polls) ||
      !I386MouseCommand(0xF6,polls))goto mouse_setup_done;
  if(!I386MouseCommand(0xF3,polls) || !I386MouseCommand(200,polls) ||
      !I386MouseCommand(0xF3,polls) || !I386MouseCommand(100,polls) ||
      !I386MouseCommand(0xF3,polls) || !I386MouseCommand(80,polls) ||
      !I386MouseType(mouse,polls) || !I386MouseCommand(0xF3,polls) ||
      !I386MouseCommand(10,polls) || !I386MouseType(mouse,polls))goto mouse_setup_done;
  if(!I386MouseCommand(0xE8,polls) || !I386MouseCommand(3,polls) ||
      !I386MouseCommand(0xE6,polls) || !I386MouseCommand(0xF3,polls) ||
      !I386MouseCommand(100,polls) || !I386MouseCommand(0xF4,polls))goto mouse_setup_done;
  if(mouse->protocol_flags)mouse->packet_size=4;
  mouse->x=320;mouse->y=240;mouse->buttons=0;mouse->packets=0;
  mouse->dropped=0;mouse->serial=0;mouse->count=0;result=TRUE;
mouse_setup_done:
  if(!I386KbcWrite(TRUE,0xAE,polls))result=FALSE;
  mouse->installed=result;
  return result;
}
#include "/Kernel/I386/MouseFeedCore.HC"
