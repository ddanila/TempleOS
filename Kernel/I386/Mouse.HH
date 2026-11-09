#ifndef I386_MOUSE_INCLUDED
#define I386_MOUSE_INCLUDED
class CI386MouseState {
  I64 x,y;
  U32 buttons,packets,dropped,serial;
  U8 bytes[3],count,installed,packet_size,protocol_flags,fourth;
};
#assert sizeof(CI386MouseState)==40;
#assert offset(CI386MouseState.count)==35;
#assert offset(CI386MouseState.installed)==36;
public extern Bool I386MouseSetup(CI386MouseState *mouse,I64 polls=100000);
public extern Bool I386MouseFeed(CI386MouseState *mouse,U8 data,U8 status);
#endif
