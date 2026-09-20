I64 BreakKeyTest()
{
  CI386KeyboardState state;
  I64 side;
  U32 saved=GetRFlags;
  for(side=0;side<4;side++) {
    I386KeyboardReset(&state);
    if(I386KeyboardBreakKey(&state,0x2E,1) || I386KeyboardBreakKey(&state,0xAE,1)) return 230;
    if((side&1) && I386KeyboardBreakKey(&state,0xE0,1)) return 231;
    if(I386KeyboardBreakKey(&state,0x1D,1) || I386KeyboardBreakKey(&state,0x2E,1) ||
        I386KeyboardBreakKey(&state,0xAE,1)) return 232;
    if((side&2) && I386KeyboardBreakKey(&state,0xE0,1)) return 233;
    if(I386KeyboardBreakKey(&state,0x38,1) || !I386KeyboardBreakKey(&state,0x2E,1) ||
        !I386KeyboardBreakKey(&state,0x2E,1) || I386KeyboardBreakKey(&state,0xAE,1)) return 234;
    //Ignore auxiliary/no-data bytes; corrupt keyboard input clears modifiers.
    if(I386KeyboardBreakKey(&state,0x2E,0x21) || I386KeyboardBreakKey(&state,0x2E,0) ||
        I386KeyboardBreakKey(&state,0x2E,0x81) || I386KeyboardBreakKey(&state,0x2E,1)) return 235;
    I386KeyboardReset(&state);
    if(I386KeyboardBreakKey(&state,0x38,1) || I386KeyboardBreakKey(&state,0x2E,1) ||
        I386KeyboardBreakKey(&state,0x1D,1) || I386KeyboardBreakKey(&state,0xE0,1) ||
        I386KeyboardBreakKey(&state,0x2E,1) || I386KeyboardBreakKey(&state,0x20,1)) return 236;
    if((GetRFlags&0x200)!=(saved&0x200)) return 237;
  }
  return 0;
}
