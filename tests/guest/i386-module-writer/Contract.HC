U0 MWStage(U8 *text){while(*text)OutU8(0xE9,*text++);}
#include "/Kernel/I386/ModuleCheck.HC"
#include "/Kernel/I386/ModulePackCore.HC"
#include "/Kernel/I386/ModuleWriteCore.HC"
U8 mw_code[64],mw_reference[512],mw_output[512],mw_scratch[4098],mw_snapshot[64];
CI386ModuleRecord mw_raw[8],mw_records[8],mw_record_snapshot[8];
CI386ModuleHeader mw_header;
U8 *mw_strings="First\0Second\0Ext\0State\0";
I64 mw_total,mw_calls,mw_fail,mw_mode,mw_limit;
I64 mw_limits[6]={1,3,17,31,512,4096};
Bool mw_bad;
U8 MWCode(U8 *context,U32 offset)
{
  no_warn context;
  if(offset>=64) {mw_bad=TRUE;return 0;}
  if(offset==63)return 0;
  return mw_code[offset];
}
I64 MWSink(U8 *context,U32 offset,U8 *buffer,U32 bytes)
{
  no_warn context;
  mw_calls++;
  if(!bytes || bytes>mw_limit || offset+bytes>mw_total || buffer!=mw_scratch+1) mw_bad=TRUE;
  if(mw_calls==mw_fail) {if(mw_mode)return -1;return bytes-1;}
  MemCpy(mw_output+offset,buffer,bytes);return bytes;
}
U0 MWReset(I64 limit)
{
  mw_calls=mw_fail=mw_bad=mw_mode=0;mw_limit=limit;
  MemSet(mw_output,0xA7,512);MemSet(mw_scratch,0xA7,4098);
  MemCpy(&mw_header,mw_reference,32);
  MemCpy(mw_records,mw_reference+mw_header.records_offset,128);
}
I64 MWWrite()
{
  return I386ModuleWriteParts(&mw_header,mw_records,mw_strings,&MWCode,0,
    &MWSink,0,mw_scratch+1,mw_limit);
}
I64 MWContract()
{
  U8 reference_code[64];
  I64 i,j,n;
  MemSet(mw_raw,0,sizeof(mw_raw));
  for(i=0;i<64;i++)mw_code[i]=i+1;
  mw_code[6]=0xE8;mw_code[19]=0x05;
  MemCpy(reference_code,mw_code,64);
  MemSet(reference_code+7,0,4);MemSet(reference_code+20,0,4);
  mw_raw[0].kind=1;mw_raw[0].offset=0;mw_raw[0].name_offset=0;mw_raw[0].name_length=5;
  mw_raw[1].kind=1;mw_raw[1].offset=16;mw_raw[1].name_offset=6;mw_raw[1].name_length=6;
  mw_raw[2].kind=2;mw_raw[2].offset=7;mw_raw[2].name_offset=13;mw_raw[2].name_length=3;
  mw_raw[3].kind=5;mw_raw[3].offset=20;mw_raw[3].name_offset=13;mw_raw[3].name_length=3;
  mw_raw[4].kind=4;mw_raw[4].offset=32;mw_raw[4].name_offset=32;
  mw_raw[5].kind=3;mw_raw[5].offset=32;mw_raw[5].name_offset=17;mw_raw[5].name_length=5;
  mw_raw[6].kind=6;mw_raw[6].offset=35;mw_raw[6].name_offset=48;
  mw_raw[7].kind=7;mw_raw[7].offset=43;mw_raw[7].name_offset=13;mw_raw[7].name_length=3;
  MWStage("WRITER oracle start\n");
  mw_total=I386ModulePackRaw(mw_reference,512,reference_code,63,mw_raw,8,mw_strings,23);
  MWStage("WRITER oracle done\n");
  if(mw_total!=247 || !I386ModuleValid(mw_reference,mw_total))return 1;
  MemCpy(mw_snapshot,mw_code,64);
  for(i=0;i<6;i++) {
    MWStage("WRITER identical start\n");
    MWReset(mw_limits[i]);MemCpy(mw_record_snapshot,mw_records,128);
    if(MWWrite!=mw_total || mw_bad || !I386ModuleValid(mw_output,mw_total) ||
        MemCmp(mw_output,mw_reference,mw_total) || MemCmp(mw_code,mw_snapshot,64) ||
        MemCmp(mw_records,mw_record_snapshot,128) || MemCmp(&mw_header,mw_reference,32))return 10+i;
    if(mw_scratch[0]!=0xA7 || mw_scratch[mw_limits[i]+1]!=0xA7 || mw_output[mw_total]!=0xA7)return 20+i;
  }
  for(j=0;j<2;j++) for(i=1;i<=15;i++) {
    MWReset(17);mw_fail=i;mw_mode=j;
    if(MWWrite || mw_calls!=i || mw_bad)return 30+i;
  }
  for(i=0;i<8;i++) {
    MWReset(17);
    switch(i) {
      case 0:mw_header.magic=0;break;
      case 1:mw_header.record_count=0xFFFFFFFF;break;
      case 2:mw_header.strings_offset=0xFFFFFFFF;break;
      case 3:mw_records[2].kind=99;break;
      case 4:mw_records[2].name_offset=0xFFFFFFFF;break;
      case 5:mw_records[6].name_offset=16;break;
      case 6:mw_records[7].offset=36;break;
      case 7:mw_code[6]=0x90;break;
    }
    n=MWWrite;mw_code[6]=0xE8;
    if(n || mw_calls)return 60+i;
  }
  MWReset(0);if(MWWrite || mw_calls)return 70;
  MWReset(4097);if(MWWrite || mw_calls)return 71;
  MWReset(17);
  if(I386ModuleWriteParts(&mw_header,mw_records,mw_strings,&MWCode,0,0,0,mw_scratch+1,17) || mw_calls)return 72;
  return 0;
}
U0 MWReport(U8 *text){while(*text)OutU8(0xE9,*text++);}
I64 mw_result=MWContract;
if(mw_result){U8 *line=MStrPrint("FAIL module-writer %d\n",mw_result);MWReport(line);Free(line);}
else MWReport("DONE module-writer 6 identical 30 write-failures 11 invalid\n");
