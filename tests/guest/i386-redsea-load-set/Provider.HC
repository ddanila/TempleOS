#include "/Kernel/Types.HH"
I64 salt=0x100000000;
I64 Add(I64 value) { salt+=value; return value*2; }
