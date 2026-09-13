#ifndef I386_KEYBOARD_SETUP_INCLUDED
#define I386_KEYBOARD_SETUP_INCLUDED
public extern Bool I386KeyboardCommand(U8 value,I64 polls=100000,I64 attempts=3);
public extern Bool I386KeyboardSetup(I64 polls=100000);
#endif
