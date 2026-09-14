I64 NativeStringTokenTest()
{
  CCmpCtrl cc; CLexFile file,*child; CI386Heap small;
  U8 input[504],*old; I64 size,i,lines=0,result,used,failures=0,successes=0;
  for(i=0;i<500;i++) input[i]='a'; input[500]=34; input[501]=59; input[502]=0;
  for(size=32;size<=2048;size+=8) {
    if(!I386HeapInit(&small,0x50000,size)) return 170;
    old=I386HeapAlloc(&small,4,FALSE); if(!old) return 171;
    old[0]='O'; old[1]='l'; old[2]='d'; old[3]=0;
    StringControlSeed(&cc,&file,input); cc.cur_str=old; cc.cur_str_len=4; cc.token=77; cc.hash_entry=0x1234;
    used=small.used; result=I386LexStringToken(&small,&cc,&lines);
    if(result==-1) {
      failures++;
      if(cc.cur_str!=old || cc.cur_str_len!=4 || cc.token!=77 || cc.hash_entry!=0x1234 ||
          old[0]!='O' || old[1]!='l' || old[2]!='d' || old[3] || small.used!=used || small.allocations!=1) return 172;
    } else {
      successes++;
      if(result!=TK_STR || cc.cur_str_len!=501 || cc.cur_str[500] || cc.hash_entry!=0x1234 ||
          I386HeapSize(&small,cc.cur_str)!=501 || small.allocations!=1) return 173;
    }
    if(!I386HeapFree(&small,cc.cur_str) || small.used || small.allocations || !I386HeapValid(&small)) return 174;
  }
  if(!failures || !successes) return 175;
  //An owned partial builder is reclaimed when a pending save point blocks EOF pop.
  input[0]=34; input[1]=59; input[2]=0; StringControlSeed(&cc,&file,input);
  child=I386LexFilePush(&string_heap,&cc); if(!child) return 176;
  child->buf=I386HeapAlloc(&string_heap,201,TRUE); if(!child->buf) return 177;
  for(i=0;i<200;i++) child->buf[i]='a'; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf;
  cc.lex_prs_stk=&file; cc.token=77; used=string_heap.used;
  if(I386LexStringToken(&string_heap,&cc,&lines)!=-1 || cc.cur_str || cc.token!=77 ||
      string_heap.used!=used || cc.lex_include_stk!=child) return 178;
  cc.lex_prs_stk=0; cc.cur_buf_ptr=child->buf;
  if(I386LexStringToken(&string_heap,&cc,&lines)!=TK_STR || cc.cur_str_len!=201 || cc.cur_str[200] ||
      cc.lex_include_stk!=&file || string_heap.allocations!=1 || !FullStringFree(&cc)) return 179;
  //A completed string remains owned/published when final lookahead fails.
  StringControlSeed(&cc,&file,input);
  child=I386LexFilePush(&string_heap,&cc); if(!child) return 180;
  child->buf=I386HeapAlloc(&string_heap,2,TRUE); if(!child->buf) return 181;
  child->buf[0]=34; LexFileSeed(child,child->buf); cc.cur_buf_ptr=child->buf; cc.lex_prs_stk=&file;
  if(I386LexStringToken(&string_heap,&cc,&lines)!=-1 || cc.token!=TK_STR || cc.cur_str_len!=1 ||
      cc.cur_str[0] || cc.flags&CCF_IN_QUOTES || cc.lex_include_stk!=child || !FullStringFree(&cc)) return 182;
  cc.lex_prs_stk=0;
  if(!I386LexFilePop(&string_heap,&cc) || string_heap.used || string_heap.allocations) return 183;
  return 0;
}
