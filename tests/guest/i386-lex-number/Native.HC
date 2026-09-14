I64 NativeNumberTest()
{
  CCmpCtrl cc; CLexFile file,*child;
  U8 *input="Ab;";
  I64 lines=0;
  NumberControlSeed(&cc,&file,input,0);
  if(I386LexNumber(&number_heap,0,'0',&lines)!=-1 ||
      I386LexNumber(&number_heap,&cc,'0',0)!=-1 ||
      I386LexNumber(&number_heap,&cc,'+',&lines)!=-1 || cc.cur_buf_ptr!=input) return 12200;
  cc.flags|=CCF_PMT;
  if(I386LexNumber(&number_heap,&cc,'0',&lines)!=-1 || cc.cur_buf_ptr!=input) return 12201;
  cc.flags&=~CCF_PMT; file.flags=LFSF_DOC;
  if(I386LexNumber(&number_heap,&cc,'0',&lines)!=-1 || cc.cur_buf_ptr!=input) return 12202;
  file.flags=0; cc.opts|=OPTF_ECHO;
  if(I386LexNumber(&number_heap,&cc,'0',&lines)!=-1 || cc.cur_buf_ptr!=input) return 12203;
  //The final common lookahead can fail even if KEEP_DOT finishes the body.
  cc.flags|=CCF_KEEP_DOT;
  if(I386LexNumber(&number_heap,&cc,'.',&lines)!=-1 || cc.token!='.' || cc.cur_buf_ptr!=input) return 12204;
  NumberControlSeed(&cc,&file,input,0);
  child=I386LexFilePush(&number_heap,&cc); if(!child) return 12205;
  child->buf=I386HeapAlloc(&number_heap,8,TRUE); if(!child->buf) return 12206;
  child->buf[0]='0'; child->buf[1]='x'; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  cc.lex_prs_stk=&file;
  if(NumberRead(&cc,&lines)!=-1 || cc.lex_include_stk!=child || cc.cur_buf_ptr!=child->buf+2) return 12207;
  cc.lex_prs_stk=0; cc.cur_buf_ptr=child->buf;
  if(NumberRead(&cc,&lines)!=TK_I64 || cc.cur_i64!=0xAB || cc.last_U16!=';' ||
      cc.lex_include_stk!=&file || number_heap.used || number_heap.allocations ||
      !I386HeapValid(&number_heap)) return 12208;
  return 0;
}
