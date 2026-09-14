#include "T:/Cases.HC"
U0 Report(U8 *s) { while(*s) OutU8(0xE9,*s++); }
U0 Capture()
{
  I64 i,*rows=CAlloc(NUMBER_CASE_COUNT*48),*row;
  U8 *input,*line;
  CCmpCtrl *cc;
  Report("START original numeric tokens\n");
  for(i=0;i<NUMBER_CASE_COUNT;i++) {
    input=number_sources+number_rows[i*2];
    cc=CmpCtrlNew(input,CCF_DONT_FREE_BUF|number_rows[i*2+1]);
    row=rows+i*6;
    row[0]=Lex(cc); row[1]=cc->cur_i64;
    if(row[0]==TK_F64) row[1]=cc->cur_f64(U64);
    row[2]=cc->cur_buf_ptr-input;
    row[3]=cc->flags&(CCF_USE_LAST_U16|CCF_LAST_WAS_DOT);
    row[4]=cc->last_U16; row[5]=cc->lex_include_stk->line_num;
    CmpCtrlDel(cc);
  }
  line=MStrPrint("EXPORT numbers.bin %X %X\n",rows,NUMBER_CASE_COUNT*48); Report(line);
  Report("DONE original numeric tokens\n");
}
Capture;
