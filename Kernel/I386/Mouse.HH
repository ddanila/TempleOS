#ifndef I386_MOUSE_INCLUDED
#define I386_MOUSE_INCLUDED
class CI386MouseState {
  I64 x,y;
  U32 buttons,packets,dropped;
  U8 bytes[3],count,installed;
};
public extern Bool I386MouseSetup(CI386MouseState *mouse,I64 polls=100000);
public extern Bool I386MouseFeed(CI386MouseState *mouse,U8 data,U8 status);
#endif
