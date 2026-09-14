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
