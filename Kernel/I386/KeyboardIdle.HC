#ifndef I386_KEYBOARD_IDLE_INCLUDED
#define I386_KEYBOARD_IDLE_INCLUDED
#include "/Kernel/I386/KeyboardRead.HH"
Bool I386KeyboardIdle(CI386KeyboardReader *reader)
{//Caller masks IRQs, so the producer cannot change the queue during the check.
  CI386KbcInput *input;
  if(!reader || !(input=reader->input)) return FALSE;
  return !input->queue.count && input->queue.dropped==reader->losses &&
    reader->losses!=0xFFFFFFFF;
}
#endif
