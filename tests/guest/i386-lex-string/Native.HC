I64 NativeStringTest()
{
  CCmpCtrl cc; CLexFile file,*child;
  U8 input[8],output[8]; Bool done;
  I64 lines=0;
  input[0]=34; input[1]=0; StringControlSeed(&cc,&file,input);
  if(I386LexStringChunk(&string_heap,&cc,output,8,0,&lines)!=-1 ||
      I386LexStringChunk(&string_heap,0,output,8,&done,&lines)!=-1 || done ||
      I386LexStringChunk(&string_heap,&cc,0,8,&done,&lines)!=-1 || done ||
      I386LexStringChunk(&string_heap,&cc,output,-1,&done,&lines)!=-1 || done ||
      I386LexStringChunk(&string_heap,&cc,output,8,&done,0)!=-1 || done || cc.cur_buf_ptr!=input) return 124;
  cc.flags|=CCF_PMT;
  if(I386LexStringChunk(&string_heap,&cc,output,8,&done,&lines)!=-1 || done || cc.cur_buf_ptr!=input) return 125;
  cc.flags&=~CCF_PMT; file.flags|=LFSF_DOC;
  if(I386LexStringChunk(&string_heap,&cc,output,8,&done,&lines)!=-1 || done || cc.cur_buf_ptr!=input) return 126;
  file.flags=0;
  if(I386LexStringChunk(&string_heap,&cc,output,8,&done,&lines)!=1 || !done || output[0]) return 127;
  input[0]='x'; input[1]='4'; input[2]='1'; input[3]=34; input[4]=0;
  StringControlSeed(&cc,&file,input);
  child=I386LexFilePush(&string_heap,&cc); if(!child) return 133;
  child->buf=I386HeapAlloc(&string_heap,8,TRUE); if(!child->buf) return 134;
  child->buf[0]=92; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  //A pending save point rejects file pop in the middle of an escape.
  cc.lex_prs_stk=&file;
  if(I386LexStringChunk(&string_heap,&cc,output,8,&done,&lines)!=-1 || done ||
      cc.lex_include_stk!=child || cc.cur_buf_ptr!=child->buf+1) return 135;
  //Errors are not resumable chunk continuations: explicitly restart this input.
  cc.lex_prs_stk=0; cc.cur_buf_ptr=child->buf;
  if(I386LexStringChunk(&string_heap,&cc,output,8,&done,&lines)!=2 || !done ||
      output[0]!='A' || output[1] || cc.lex_include_stk!=&file ||
      cc.cur_buf_ptr!=input+4 || string_heap.used || string_heap.allocations) return 136;
  return 0;
}

I64 NativeCharTest()
{
  CCmpCtrl cc; CLexFile file,*child;
  U8 input[16]; I64 i,lines=0;
  input[0]=39; input[1]=59; input[2]=0;
  StringControlSeed(&cc,&file,input);
  if(I386LexChar(&string_heap,0,&lines)!=-1 || I386LexChar(&string_heap,&cc,0)!=-1 || cc.cur_buf_ptr!=input) return 144;
  cc.flags|=CCF_NO_CHAR_CONST;
  if(I386LexChar(&string_heap,&cc,&lines)!=-1 || cc.cur_buf_ptr!=input) return 145;
  cc.flags=CCF_PMT;
  if(I386LexChar(&string_heap,&cc,&lines)!=-1 || cc.cur_buf_ptr!=input) return 146;
  cc.flags=CCF_DONT_FREE_BUF;
  //The original lexer accepts EOF as an implicit terminator.
  for(i=0;i<3;i++) {
    input[0]=0;
    if(i) { input[0]=65; input[1]=0; }
    if(i==2) input[0]=92;
    StringControlSeed(&cc,&file,input);
    if(I386LexChar(&string_heap,&cc,&lines)!=TK_CHAR_CONST ||
        cc.last_U16!=TK_EOF || cc.cur_buf_ptr!=input+(i!=0)) return 147;
    if(!i && cc.cur_i64 || i==1 && cc.cur_i64!=65 || i==2 && cc.cur_i64!=92) return 148;
  }
  input[0]='x'; input[1]='4'; input[2]='1'; input[3]=39; input[4]=59; input[5]=0;
  StringControlSeed(&cc,&file,input);
  child=I386LexFilePush(&string_heap,&cc); if(!child) return 149;
  child->buf=I386HeapAlloc(&string_heap,8,TRUE); if(!child->buf) return 150;
  child->buf[0]=92; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  cc.lex_prs_stk=&file; cc.token=77; cc.cur_i64=123;
  if(I386LexChar(&string_heap,&cc,&lines)!=-1 || cc.lex_include_stk!=child ||
      cc.cur_buf_ptr!=child->buf+1 || cc.token!=77 || cc.cur_i64!=123) return 151;
  cc.lex_prs_stk=0; cc.cur_buf_ptr=child->buf;
  if(I386LexChar(&string_heap,&cc,&lines)!=TK_CHAR_CONST || cc.cur_i64!=65 ||
      cc.last_U16!=59 || cc.cur_buf_ptr!=input+5 || cc.lex_include_stk!=&file ||
      string_heap.used || string_heap.allocations) return 152;
  //A final-lookahead failure leaves the successfully decoded token published.
  input[0]=39; input[1]=0;
  StringControlSeed(&cc,&file,input);
  child=I386LexFilePush(&string_heap,&cc); if(!child) return 153;
  child->buf=I386HeapAlloc(&string_heap,8,TRUE); if(!child->buf) return 154;
  child->buf[0]=39; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  cc.lex_prs_stk=&file;
  if(I386LexChar(&string_heap,&cc,&lines)!=-1 || cc.token!=TK_CHAR_CONST || cc.cur_i64 ||
      cc.lex_include_stk!=child) return 155;
  cc.lex_prs_stk=0;
  if(I386LexFilePop(&string_heap,&cc)!=1 || string_heap.used || string_heap.allocations) return 156;
  return 0;
}
