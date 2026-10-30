I64 PublicTSContract()
{
  F64 start=tS(),middle,finish;I64 mask=0;
  Sleep(120);middle=tS();Sleep(120);finish=tS();
  if(start>=0 && middle>start && finish>middle)mask|=1;
  if(middle-start<10.0 && finish-middle<10.0)mask|=2;
  return mask;
}
