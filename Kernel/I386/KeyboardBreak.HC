#include "/Kernel/I386/KeyboardEvent.HH"
public Bool I386KeyboardBreakKey(CI386KeyboardState *state,U8 data,U8 status)
{//Observe every byte; only an unextended C make with Ctrl and Alt requests Break.
  CI386KeyEvent event;
  if(I386KeyboardFeed(state,data,status,&event)!=1) return FALSE;
  return event.type==2 && ((event.scan>>32)&255)==0x2E && (event.scan&0xC00)==0xC00;
}
