#include "/Kernel/DateTypes.HH"
#include "/Kernel/DateCore.HC"
//Caller-controlled offset, matching the original zero-initialized global.
CDate local_time_offset;

U8 NativeDateRead(U8 index)
{//Use the same disabled-NMI selector policy as the boot-owned RTC helpers.
  OutU8(0x70,index|0x80); InU8(0x80); return InU8(0x71);
}
CDate NativeNow()
{
  CDateStruct ds;
  U8 *raw=&ds,b,hour,second;
  U32 flags=I386IrqSave;
  I64 i,attempt;
  Bool stable=FALSE;
  for(i=0;i<sizeof(CDateStruct);i++) raw[i]=0;
  for(attempt=0;attempt<10000;attempt++) {
    if(!(NativeDateRead(0x0A)&0x80)) {
      second=NativeDateRead(0); ds.sec=second;
      ds.min=NativeDateRead(2); hour=NativeDateRead(4);
      ds.day_of_mon=NativeDateRead(7); ds.mon=NativeDateRead(8);
      ds.year=NativeDateRead(9); b=NativeDateRead(0x0B);
      if(!(NativeDateRead(0x0A)&0x80) && NativeDateRead(0)==second) {
        stable=TRUE; break;
      }
    }
  }
  I386IrqRestore(flags);
  if(!stable) throw('RtcDate');
  ds.hour=hour&0x7F;
  if(!(b&4)) {
    ds.sec=Bcd2Bin(ds.sec); ds.min=Bcd2Bin(ds.min);
    ds.hour=Bcd2Bin(ds.hour); ds.day_of_mon=Bcd2Bin(ds.day_of_mon);
    ds.mon=Bcd2Bin(ds.mon); ds.year=Bcd2Bin(ds.year);
  }
  if(!(b&2)) {
    if(ds.hour==12) ds.hour=0;
    if(hour&0x80) ds.hour+=12;
  }
  ds.year+=2000;
  if(ds.mon<1 || ds.mon>12 || ds.day_of_mon<1 || ds.day_of_mon>31 ||
      ds.hour>23 || ds.min>59 || ds.sec>59) throw('RtcDate');
  return Struct2Date(&ds)-local_time_offset;
}
