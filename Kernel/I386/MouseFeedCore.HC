#ifndef MOUSE_FEED_FUNCTION
#define MOUSE_FEED_FUNCTION I386MouseFeed
#endif
public Bool MOUSE_FEED_FUNCTION(CI386MouseState *mouse,U8 data,U8 status)
{//Decode a three- or four-byte PS/2 packet. Positive screen Y points down.
  I64 dx,dy,size;
  if(!mouse || !mouse->installed || !(status&0x20) || status&0xC0) return FALSE;
  if(!mouse->count) {
    if(!(data&8)) { if(mouse->dropped!=U32_MAX) mouse->dropped++; return FALSE; }
  }
  size=3;if(mouse->packet_size==4)size=4;
  if(mouse->count<3)mouse->bytes[mouse->count]=data;
  else mouse->fourth=data;
  mouse->count++;
  if(mouse->count<size) return TRUE;
  mouse->count=0;
  if(size==3)mouse->fourth=0;
  dx=mouse->bytes[1];dy=mouse->bytes[2];
  if(mouse->bytes[0]&0x10)dx-=256;
  if(mouse->bytes[0]&0x20)dy-=256;
  mouse->x+=dx; mouse->y-=dy;
#ifndef MOUSE_FEED_UNBOUNDED
  if(mouse->x<0) mouse->x=0; else if(mouse->x>639) mouse->x=639;
  if(mouse->y<0) mouse->y=0; else if(mouse->y>479) mouse->y=479;
#endif
  mouse->buttons=mouse->bytes[0]&7;
  if(mouse->packets!=U32_MAX) mouse->packets++;
  mouse->serial++;
  return TRUE;
}
