#include "T:/Cases.HC"
#ifdef NATIVE_NUMBER_TEST
#include "T:/NativeOracle.HC"
#else
#include "T:/Oracle.HC"
#endif
U0 NumberControlSeed(CCmpCtrl *cc,CLexFile *file,U8 *input,I64 flags)
{
  I64 i; U8 *bytes=cc;
  for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF|flags,0,char_bmp_alpha_numeric);
  LexFileSeed(file,input); cc->lex_include_stk=file; cc->cur_buf_ptr=input;
}
I64 NumberTest()
{
  CCmpCtrl cc; CLexFile file;
  I64 i,token,lines;
  U64 value,*row;
  U8 *input;
  for(i=0;i<NUMBER_CASE_COUNT;i++) {
    input=number_sources+number_rows[i*2]; row=number_oracle+i*6;
    NumberControlSeed(&cc,&file,input,number_rows[i*2+1]); lines=0;
    token=NumberRead(&cc,&lines);
    value=cc.cur_i64; if(token==TK_F64) value=cc.cur_f64(U64);
    if(token!=row[0]) return i*10+2;
    if(value!=row[1]) return i*10+3;
    if(cc.cur_buf_ptr!=input+row[2]) return i*10+4;
    if((cc.flags&(CCF_USE_LAST_U16|CCF_LAST_WAS_DOT))!=row[3]) return i*10+5;
    if(cc.last_U16!=row[4] || file.line_num!=row[5] || lines!=row[5]-1) return i*10+6;
  }
  return 0;
}
