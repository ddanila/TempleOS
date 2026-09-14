I64 NativeInputTest()
{
  CCmpCtrl *cc=StateAlloc(sizeof(CCmpCtrl));
  CLexFile *root,*child;
  U8 *buffer=StateAlloc(8),*saved;
  I64 lines=0,i;
  if(!cc || !buffer) return 66;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF,0,0);
  if(I386LexRawChar(&state_heap,0,&lines)!=-1 || InputRead(cc,&lines)!=-1) return 67;
  root=InputPush(cc); if(!root) return 68;
  buffer[0]='x'; LexFileSeed(root,buffer); cc->cur_buf_ptr=buffer;
  if(I386LexRawChar(&state_heap,cc,0)!=-1) return 69;
  for(i=0;i<3;i++) {
    if(i==0) cc->flags|=CCF_PMT;
    if(i==1) cc->opts|=OPTF_ECHO;
    if(i==2) root->flags|=LFSF_DOC;
    if(InputRead(cc,&lines)!=-1 || cc->cur_buf_ptr!=buffer || lines) return 70;
    cc->flags=CCF_DONT_FREE_BUF; cc->opts=0; root->flags=0;
  }
  child=InputPush(cc); if(!child) return 71;
  LexFileSeed(child,StateAlloc(8)); cc->cur_buf_ptr=child->buf;
  if(!I386LexPush(&state_heap,cc)) return 72;
  saved=cc->cur_buf_ptr;
  if(InputRead(cc,&lines)!=-1 || cc->cur_buf_ptr!=saved || cc->lex_include_stk!=child) return 73;
  if(!I386LexPop(&state_heap,cc,FALSE)) return 74;
  root->flags=LFSF_DOC;
  if(InputRead(cc,&lines)!=-1 || cc->lex_include_stk!=child || cc->cur_buf_ptr!=saved) return 75;
  root->flags=0;
  if(InputRead(cc,&lines)!='x' || cc->lex_include_stk!=root || InputRead(cc,&lines)) return 76;
  if(!InputPop(cc)) return 77;
  StateFree(buffer); StateFree(cc);
  if(state_free_errors || state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap)) return 78;
  return 0;
}
