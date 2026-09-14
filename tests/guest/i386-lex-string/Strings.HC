#include "T:/Cases.HC"
U0 StringControlSeed(CCmpCtrl *cc,CLexFile *file,U8 *input)
{
  I64 i; U8 *bytes=cc;
  for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF|CCF_IN_QUOTES,0,char_bmp_alpha_numeric);
  LexFileSeed(file,input); cc->lex_include_stk=file; cc->cur_buf_ptr=input;
}
I64 StringCase(U8 *input,U8 *expected,I64 length,I64 consumed,I64 dollars,I64 newlines,I64 capacity)
{
  CCmpCtrl cc; CLexFile file;
  U8 output[16]; Bool done=FALSE;
  I64 lines=0,total=0,count,i,attempts=0;
  StringControlSeed(&cc,&file,input);
  while(!done) {
    for(i=0;i<16;i++) output[i]=0xA5;
    count=StringChunk(&cc,output+2,capacity,&done,&lines);
    if(count<0 || count>=capacity || total+count>length || ++attempts>length+1) return 110;
    for(i=0;i<2;i++) if(output[i]!=0xA5) return 111;
    for(i=0;i<count;i++) if(output[i+2]!=expected[total+i]) return 112;
    for(i=count+2;i<16;i++) if(output[i]!=0xA5) return 113;
    total+=count;
  }
  if(total!=length || cc.cur_buf_ptr!=input+consumed || cc.dollar_cnt!=dollars ||
      lines!=newlines || file.line_num!=newlines+1 || !(cc.flags&CCF_IN_QUOTES)) return 114;
  return 0;
}
I64 StringTest()
{
  I64 i,j,capacity,result,*row,value,expected;
  U8 input[512],output[512],*hex="0123456789abcdef";
  for(i=0;i<24;i++) {
    row=string_rows+i*7;
    for(capacity=2;capacity<=8;capacity++) {
      result=StringCase(string_sources+row[0],string_expected+row[2],row[3],row[4],row[5],row[6],capacity);
      if(result) return result;
    }
  }
  input[0]=92; input[4]=34; input[5]=33; input[6]=0; output[1]=0;
  for(i=0;i<256;i++) {
    input[2]=hex[i>>4]; input[3]=hex[i&15]; output[0]=i;
    for(j=0;j<2;j++) {
      input[1]='x'; if(j) input[1]='X';
      for(capacity=2;capacity<=4;capacity++) {
        result=StringCase(input,output,2,5,0,0,capacity);
        if(result) return result;
      }
    }
  }
  for(i=0;i<320;i++) input[i]=output[i]='a'+i%26;
  input[320]=34; input[321]=33; input[322]=0; output[320]=0;
  for(capacity=2;capacity<=8;capacity++) {
    result=StringCase(input,output,321,321,0,0,capacity);
    if(result) return result;
  }
  for(i=-512;i<1024;i++) {
    value=i; expected=i; if('a'<=i<='z') expected-=32;
    if(ToUpper(value)!=expected) return 115;
  }
  value=0x100000061; if(ToUpper(value)!=value) return 116;
  value=-0x100000000; if(ToUpper(value)!=value) return 117;
  value='a'; if(ToUpper(value++)!='A' || value!='b') return 118;
  if(ToUpper(ToUpper(value))!='B') return 119;
  return 0;
}
