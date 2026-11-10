#include "/Kernel/Types.HH"
U8 zi_byte;
I64 zi_integer;
U8 *zi_pointer;
U0 (*zi_callback)(U8 *);
U8 zi_array[37];
class CZIRecord {U8 tag;U32 count;U8 *pointer;};
CZIRecord zi_record;
U8 zi_initialized_array[8]={7,9,0,0,0,0,0,0};
I64 zi_explicit=0x123456789ABCDEF;
I64 ZIEntry(){return zi_explicit;}
