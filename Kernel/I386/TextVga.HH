#ifndef I386_TEXT_VGA_INCLUDED
#define I386_TEXT_VGA_INCLUDED
#include "/Kernel/I386/Text.HH"
//Return uploaded text rows, zero when clean, or -1 without consuming damage.
public extern I64 I386TextPresent(CI386Text *text);
#endif
