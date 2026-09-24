#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/Mouse.HH"
Bool I386MouseCommand(U8 value,I64 polls)
{
  U8 reply,status;
  if(!I386KbcWrite(TRUE,0xD4,polls) || !I386KbcWrite(FALSE,value,polls) ||
      !I386KbcReadWait(&reply,&status,polls)) return FALSE;
  return status&0x20 && !(status&0xC0) && reply==0xFA;
}
public Bool I386MouseSetup(CI386MouseState *mouse,I64 polls=100000)
{//Boot-only exclusive 8042 ownership, IF clear and IRQ1/12 masked.
  U8 config,status;
  if(!mouse || polls<1 || polls>100000 || !I386KbcDrain(polls) ||
      !I386KbcWrite(TRUE,0xA8,polls) || !I386KbcWrite(TRUE,0x20,polls) ||
      !I386KbcReadWait(&config,&status,polls) || status&0xE0) return FALSE;
  config=(config|3)&~0x20;
  if(!I386KbcWrite(TRUE,0x60,polls) || !I386KbcWrite(FALSE,config,polls) ||
      !I386MouseCommand(0xF6,polls) || !I386MouseCommand(0xF4,polls)) return FALSE;
  mouse->x=320; mouse->y=240; mouse->buttons=0; mouse->packets=0;
  mouse->dropped=0; mouse->count=0; mouse->installed=TRUE;
  return TRUE;
}
public Bool I386MouseFeed(CI386MouseState *mouse,U8 data,U8 status)
{//Decode one standard three-byte PS/2 packet. Positive screen Y points down.
  I64 dx,dy;
  if(!mouse || !mouse->installed || !(status&0x20) || status&0xC0) return FALSE;
  if(!mouse->count) {
    if(!(data&8)) { if(mouse->dropped!=U32_MAX) mouse->dropped++; return FALSE; }
    if(data&0xC0) { if(mouse->dropped!=U32_MAX) mouse->dropped++; return FALSE; }
  }
  mouse->bytes[mouse->count++]=data;
  if(mouse->count<3) return TRUE;
  mouse->count=0; dx=mouse->bytes[1](I8); dy=mouse->bytes[2](I8);
  mouse->x+=dx; mouse->y-=dy;
  if(mouse->x<0) mouse->x=0; else if(mouse->x>639) mouse->x=639;
  if(mouse->y<0) mouse->y=0; else if(mouse->y>479) mouse->y=479;
  mouse->buttons=mouse->bytes[0]&7;
  if(mouse->packets!=U32_MAX) mouse->packets++;
  return TRUE;
}
