I64 NativeIdentTest()
{
  CCmpCtrl cc; CLexFile file,*child; CHash *entry; U8 input[8],output[146]; I64 i,lines=0;
  input[0]=0; IdentSeed(&cc,&file,input); cc.token=77; cc.cur_str=0x1234;
  if(I386LexIdentScan(&ident_heap,0,'a',output,144,&entry,&lines)!=-1 ||
      I386LexIdentScan(&ident_heap,&cc,'a',0,144,&entry,&lines)!=-1 ||
      I386LexIdentScan(&ident_heap,&cc,'a',output,1,&entry,&lines)!=-1 ||
      I386LexIdentScan(&ident_heap,&cc,'a',output,144,0,&lines)!=-1 ||
      I386LexIdentScan(&ident_heap,&cc,'a',output,144,&entry,0)!=-1 ||
      I386LexIdentScan(&ident_heap,&cc,'9',output,144,&entry,&lines)!=-1 || cc.cur_buf_ptr!=input) return 130;
  cc.flags|=CCF_KEEP_AT_SIGN;
  if(I386LexIdentScan(&ident_heap,&cc,'@',output,144,&entry,&lines)!=-1 || cc.cur_buf_ptr!=input) return 131;
  cc.flags=CCF_DONT_FREE_BUF; cc.opts|=OPTF_ECHO;
  if(I386LexIdentScan(&ident_heap,&cc,'a',output,144,&entry,&lines)!=-1 || cc.cur_buf_ptr!=input) return 132;
  cc.opts&=~OPTF_ECHO;
  if(I386LexIdentScan(&ident_heap,&cc,'a',output,144,&entry,&lines)!=2 || entry ||
      output[0]!='a' || output[1] || cc.cur_buf_ptr!=input || cc.token!=77 || cc.cur_str!=0x1234) return 133;
  input[0]='c'; input[1]=59; input[2]=0; IdentSeed(&cc,&file,input);
  child=I386LexFilePush(&ident_heap,&cc); if(!child) return 134;
  child->buf=I386HeapAlloc(&ident_heap,8,TRUE); if(!child->buf) return 135;
  child->buf[0]='b'; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  cc.lex_prs_stk=&file; cc.token=77; cc.local_var_entry=0x1234;
  if(I386LexIdentScan(&ident_heap,&cc,'a',output,144,&entry,&lines)!=-1 || entry ||
      cc.token!=77 || cc.local_var_entry!=0x1234 || cc.lex_include_stk!=child) return 136;
  cc.lex_prs_stk=0; cc.cur_buf_ptr=child->buf;
  if(I386LexIdentScan(&ident_heap,&cc,'a',output,144,&entry,&lines)!=4 || entry ||
      output[0]!='a' || output[1]!='b' || output[2]!='c' || output[3] || cc.local_var_entry ||
      cc.cur_buf_ptr!=input+2 || cc.lex_include_stk!=&file || ident_heap.used || ident_heap.allocations) return 137;
  return 0;
}
