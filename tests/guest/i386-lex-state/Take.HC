I64 NativeTakeTest()
{
  CCmpCtrl cc;
  CLexFile *root,*child;
  CI386Heap small;
  U8 *source,*name,*saved,*bytes;
  I64 i,size,used,count,lines=0;
  U32 flags=I386IrqSave;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,0,0);
  root=I386LexFilePush(&state_heap,&cc); if(!root) return 80;
  LexFileSeed(root,"z"); cc.cur_buf_ptr=root->buf;
  source=StateAlloc(4); if(!source) return 81;
  source[0]='a'; source[1]=10; source[2]='b';
  used=state_heap.used; count=state_heap.allocations;
  if(I386LexIncludeTake(&state_heap,&cc,"bad",source+1) ||
      I386LexIncludeTake(&state_heap,&cc,"bad","constant")) return 82;
  source[3]='x';
  if(I386LexIncludeTake(&state_heap,&cc,"bad",source)) return 83;
  source[3]=0;
  for(i=0;i<3;i++) {
    if(i==0) cc.flags|=CCF_PMT;
    if(i==1) cc.opts|=OPTF_ECHO;
    if(i==2) root->flags|=LFSF_DOC;
    if(I386LexIncludeTake(&state_heap,&cc,"bad",source)) return 84;
    cc.flags=CCF_DONT_FREE_BUF; cc.opts=0; root->flags=0;
  }
  cc.cur_str=source;
  if(I386LexIncludeTake(&state_heap,&cc,"bad",source)) return 85;
  cc.cur_str=0;
  root->full_name=source;
  if(I386LexIncludeTake(&state_heap,&cc,"bad",source)) return 86;
  root->full_name=0;
  if(state_heap.used!=used || state_heap.allocations!=count || cc.lex_include_stk!=root ||
      cc.cur_buf_ptr!=root->buf || GetRFlags&0x200) return 87;
  cc.flags|=CCF_USE_LAST_U16; cc.last_U16=0x141;
  SetRFlags(GetRFlags|0x200);
  if(!I386LexIncludeTake(&state_heap,&cc,"child",source,TRUE) || !(GetRFlags&0x200)) return 88;
  child=cc.lex_include_stk; name=child->full_name;
  if(child==root || child->next!=root || child->depth!=0 || child->line_num!=1 ||
      child->flags!=LFSF_DEFINE || child->buf!=source || child->buf_ptr!=source ||
      child->line_start!=source || cc.cur_buf_ptr!=source || cc.flags&CCF_USE_LAST_U16 ||
      root->last_U16!='A' || I386HeapSize(&state_heap,name)!=6 || name[0]!='c' || name[5] ||
      state_heap.allocations!=count+2) return 89;
  if(I386LexIncludeTake(&state_heap,&cc,"duplicate",source)) return 90;
  if(InputRead(&cc,&lines)!='a' || InputRead(&cc,&lines)!=10 || InputRead(&cc,&lines)!='b' ||
      lines!=1 || child->line_num!=2) return 91;
  if(!I386LexPush(&state_heap,&cc)) return 92;
  saved=cc.cur_buf_ptr;
  if(InputRead(&cc,&lines)!=-1 || cc.lex_include_stk!=child || cc.cur_buf_ptr!=saved) return 93;
  if(!I386LexPop(&state_heap,&cc,FALSE) || InputRead(&cc,&lines)!='A' ||
      cc.lex_include_stk!=root || I386HeapSize(&state_heap,source)!=-1 ||
      I386HeapSize(&state_heap,name)!=-1 || state_heap.allocations!=count-1 ||
      InputRead(&cc,&lines)!='z' || InputRead(&cc,&lines) || !(GetRFlags&0x200)) return 94;
  I386IrqSave;
  //Only the source allocation fits, or source plus record: neither failure transfers it.
  for(size=24;size<128;size+=8) {
    if(!I386HeapInit(&small,0x61000,size)) return 95;
    source=I386HeapAlloc(&small,1,TRUE); if(!source) return 96;
    used=small.used;
    cc.flags=CCF_DONT_FREE_BUF|CCF_USE_LAST_U16; cc.last_U16='Q';
    if(I386LexIncludeTake(&small,&cc,"child",source) || small.used!=used ||
        small.allocations!=1 || I386HeapSize(&small,source)!=1 || cc.lex_include_stk!=root ||
        cc.cur_buf_ptr!=root->buf+1 || cc.flags!=(CCF_DONT_FREE_BUF|CCF_USE_LAST_U16) ||
        cc.last_U16!='Q' || root->last_U16!='A' || !I386HeapFree(&small,source)) return 97;
  }
  source=StateAlloc(1);
  if(!source || !I386LexIncludeTake(&state_heap,&cc,"empty",source) ||
      InputRead(&cc,&lines)!='Q' || cc.lex_include_stk!=root || InputRead(&cc,&lines)) return 98;
  if(!InputPop(&cc) || state_heap.used || state_heap.allocations || !I386HeapValid(&state_heap)) return 99;
  I386IrqRestore(flags);
  return 0;
}
