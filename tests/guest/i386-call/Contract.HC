I64 pc_count;
I64 PCWide(){return 0x1122334455667788;}
I64 PCNegative(){return -1234567890123;}
F64 PCFloat(){return 1.25;}
I64 PCZero(){pc_count++;return 0;}
I64 PCNested(){return Call(&PCWide)+1;}
I64 PCThrow(){pc_count++;throw('CallTest');return 0;}
U0 PCLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 PCCheck()
{
  I64 mask=0,value,*result,stack,after;U8 *s;Bool caught=FALSE;
  pc_count=0;stack=GetRSP;
  if(Call(NULL)==0)mask|=1;
  if(Call(&PCWide)==0x1122334455667788)mask|=2;
  if(Call(&PCNegative)==-1234567890123)mask|=4;
  value=Call(&PCFloat);if(value(F64)==1.25)mask|=8;
  if(Call(&PCZero)==0 && pc_count==1)mask|=16;
  if(Call(&PCNested)==0x1122334455667789)mask|=32;
  try{Call(&PCThrow);}catch{caught=Fs->except_ch=='CallTest';Fs->catch_except=TRUE;}
  if(caught && pc_count==2)mask|=64;
  after=GetRSP;
  if(after==stack && Call(&PCWide)==0x1122334455667788)mask|=128;
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT call-mask.bin %X 8\n",result);PCLog(s);Free(s);
  PCLog("PUBLIC CALL DONE\n");Sleep(1000);
}
PCCheck;
