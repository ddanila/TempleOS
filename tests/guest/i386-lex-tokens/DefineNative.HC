I64 DefineCase(U8 *input,U8 *expected)
{
  CCmpCtrl cc; CLexFile file; I64 lines=0,length=0; U8 *text;
  IdentSeed(&cc,&file,input); cc.token=77; cc.cur_i64=0x100000001;
  text=I386LexDefineBody(&token_heap,&cc,&lines);
  if(!text || StrCmp(text,expected) || cc.token!=77 || cc.cur_i64!=0x100000001 || cc.cur_str) return 1;
  while(expected[length]) length++;
  if(I386HeapSize(&token_heap,text)!=length+1 || !I386HeapFree(&token_heap,text)) return 2;
  return 0;
}
I64 DefineNativeTest()
{
  CCmpCtrl cc; CLexFile file; CI386Heap scratch;
  U8 input[503],*text; I64 i,size,lines=0,failed=0,passed=0;
  for(i=0;i<500;i++) input[i]=97;
  input[500]=10; input[501]=59; input[502]=0;
  for(size=32;size<=2048;size+=8) {
    if(!I386HeapInit(&scratch,0x70000,size)) return 440;
    IdentSeed(&cc,&file,input); cc.token=77;
    text=I386LexDefineBody(&scratch,&cc,&lines);
    if(text) {
      passed++;
      if(I386HeapSize(&scratch,text)!=501 || text[500]) return 441;
      for(i=0;i<500;i++) if(text[i]!=97) return 442;
      if(!I386HeapFree(&scratch,text)) return 443;
    } else failed++;
    if(cc.token!=77 || cc.cur_str || scratch.used || scratch.allocations || !I386HeapValid(&scratch)) return 444;
  }
  if(!failed || !passed) return 445;
  IdentSeed(&cc,&file," x\\\ry\n;");
  text=I386LexDefineBody(&token_heap,&cc,&lines);
  if(!text || StrCmp(text,"xy") || cc.cur_buf_ptr!=file.buf+6 || cc.last_U16!=10 ||
      cc.flags&CCF_USE_LAST_U16 || file.line_num!=2 || !I386HeapFree(&token_heap,text)) return 446;
  IdentSeed(&cc,&file,"x",CCF_PMT);
  if(I386LexDefineBody(&token_heap,&cc,&lines)) return 447;
  return 0;
}
