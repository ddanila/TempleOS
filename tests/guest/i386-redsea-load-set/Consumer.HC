#include "/Kernel/Types.HH"
import I64 salt;
import I64 Add(I64 value);
I64 Main(I64 a,I64 b) { I64 result=Add(a); return result+salt+b; }
