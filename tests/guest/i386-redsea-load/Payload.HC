#include "/Kernel/Types.HH"
I64 salt=0x100000000;
I64 Main(I64 a,I64 b) { salt+=a; return salt+b; }
