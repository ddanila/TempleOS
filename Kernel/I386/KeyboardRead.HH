#ifndef I386_KEYBOARD_READ_INCLUDED
#define I386_KEYBOARD_READ_INCLUDED
#include "/Kernel/I386/KeyboardEvent.HH"
#include "/Kernel/I386/KbcInput.HH"
class CI386KeyboardReader {
  CI386KeyboardState state;
  CI386KbcInput *input;
  U32 losses;
};
public extern Bool I386KeyboardReadInit(CI386KeyboardReader *reader,CI386KbcInput *input);
public extern I64 I386KeyboardRead(CI386KeyboardReader *reader,CI386KeyEvent *event,Bool wait=TRUE);
#endif
