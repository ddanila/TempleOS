#ifndef I386_CONSOLE_PIT_READ_INCLUDED
#define I386_CONSOLE_PIT_READ_INCLUDED
//One console-owned PIT reader shared by random-clock and literal-report paths.
#define I386_PIT_READ_FUNCTION NativeRandPitRead
#include "/Kernel/I386/PitRead.HC"
#endif
