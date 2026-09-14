I64 NativeConditionalTest()
{
  CCmpCtrl cc; CLexFile file; CI386Heap scratch; I64 lines=0;
  IdentSeed(&cc,&file,"#if 1 2"); cc.htc.hash_table_lst=keywords.table;
  if(ConditionalNext(&cc,&lines)!=-4 || !ConditionalFree(&cc)) return 150;
  if(!I386HeapInit(&scratch,0x70000,32)) return 151;
  IdentSeed(&cc,&file,"#ifdef Exists 1"); cc.htc.hash_table_lst=keywords.table;
  if(I386LexNext(&scratch,&cc,&token_tables,"Macro",&lines)!=-1 || cc.flags&CCF_NO_DEFINES ||
      !cc.cur_str || StrCmp(cc.cur_str,"ifdef") || !I386HeapFree(&scratch,cc.cur_str) ||
      scratch.used || scratch.allocations || !I386HeapValid(&scratch)) return 152;
  IdentSeed(&cc,&file,"#endif 8 9"); cc.htc.hash_table_lst=keywords.table;
  if(!I386LexIncludeCopy(&token_heap,&cc,"Child","#ifdef Missing 7")) return 153;
  cc.lex_prs_stk=1;
  if(ConditionalNext(&cc,&lines)!=-1 || cc.lex_include_stk==&file || cc.flags&CCF_NO_DEFINES) return 154;
  cc.lex_prs_stk=0;
  if(!I386LexFilePop(&token_heap,&cc) || cc.lex_include_stk!=&file || !ConditionalFree(&cc)) return 155;
  return 0;
}
