I64 NativePunctTest()
{
  CCmpCtrl cc; CLexFile file,*child; I64 lines=0,old,result; U8 input[16];
  input[0]='='; input[1]=59; input[2]=0;
  PunctSeed(&cc,&file,input,0);
  if(I386LexPunct(&punct_heap,0,60,&punct_tables,&lines)!=-1 ||
      I386LexPunct(&punct_heap,&cc,60,0,&lines)!=-1 ||
      I386LexPunct(&punct_heap,&cc,60,&punct_tables,0)!=-1 ||
      I386LexPunct(&punct_heap,&cc,'A',&punct_tables,&lines)!=-1 || cc.cur_buf_ptr!=input) return 210;
  cc.opts|=OPTF_ECHO;
  if(I386LexPunct(&punct_heap,&cc,60,&punct_tables,&lines)!=-1 || cc.cur_buf_ptr!=input) return 211;
  //Keep tables writable and supplied by the caller.
  old=punct_first['!']; punct_first['!']=TK_PLUS_PLUS<<16+'=';
  cc.flags=CCF_DONT_FREE_BUF; cc.opts&=~OPTF_ECHO;
  result=I386LexPunct(&punct_heap,&cc,'!',&punct_tables,&lines);
  punct_first['!']=old;
  if(result!=TK_PLUS_PLUS || cc.last_U16!=59 || cc.cur_buf_ptr!=input+2) return 212;
  //An include boundary bisects a nested-comment delimiter.
  input[0]='*'; input[1]='x'; input[2]='*'; input[3]='/'; input[4]='*'; input[5]='/'; input[6]=59; input[7]=0;
  PunctSeed(&cc,&file,input,0);
  child=I386LexFilePush(&punct_heap,&cc); if(!child) return 213;
  child->buf=I386HeapAlloc(&punct_heap,8,TRUE); if(!child->buf) return 214;
  child->buf[0]='*'; child->buf[1]='/'; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  cc.lex_prs_stk=&file; cc.token=77;
  if(I386LexPunct(&punct_heap,&cc,'/',&punct_tables,&lines)!=-1 || cc.token!=77 ||
      cc.lex_include_stk!=child || cc.cur_buf_ptr!=child->buf+2) return 215;
  cc.lex_prs_stk=0; cc.cur_buf_ptr=child->buf;
  if(I386LexPunct(&punct_heap,&cc,'/',&punct_tables,&lines)!=-2 || cc.token!=77 ||
      cc.lex_include_stk!=&file || cc.cur_buf_ptr!=input+6 || punct_heap.used || punct_heap.allocations) return 216;
  if(PunctToken(&cc,&lines)!=59) return 217;
  //A completed operator remains published if its final lookahead cannot pop.
  input[0]=59; input[1]=0; PunctSeed(&cc,&file,input,0);
  child=I386LexFilePush(&punct_heap,&cc); if(!child) return 218;
  child->buf=I386HeapAlloc(&punct_heap,8,TRUE); if(!child->buf) return 219;
  child->buf[0]='='; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  cc.lex_prs_stk=&file;
  if(I386LexPunct(&punct_heap,&cc,'!',&punct_tables,&lines)!=-1 ||
      cc.token!=TK_NOT_EQU || cc.lex_include_stk!=child) return 220;
  cc.lex_prs_stk=0;
  if(!I386LexFilePop(&punct_heap,&cc) || punct_heap.used || punct_heap.allocations) return 221;
  //Line comments must observe caller changes to the shared classification bitmap.
  input[0]='/'; input[1]='a'; input[2]=59; input[3]='!'; input[4]=0;
  PunctSeed(&cc,&file,input,CCF_KEEP_NEW_LINES); old=Btr(char_bmp_non_eol,59);
  result=I386LexPunct(&punct_heap,&cc,'/',&punct_tables,&lines);
  if(old) Bts(char_bmp_non_eol,59);
  if(result!=10 || cc.last_U16!='!' || cc.cur_buf_ptr!=input+4) return 222;
  return 0;
}
