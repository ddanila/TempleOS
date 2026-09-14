I64 PublishNativeTest()
{
  CCmpCtrl cc; CLexFile file; CHashTable table; CHashGeneric keyword; CHash *bucket=0;
  CHashDefineStr *entry; CI386Heap scratch; U8 input[502],*old; Bool ok;
  I64 i,size,lines=0,failed=0,passed=0;
  for(i=0;i<500;i++) input[i]=97; input[500]=10; input[501]=0;
  for(size=32;size<=2048;size+=8) {
    if(!I386HeapInit(&scratch,0x70000,size)) return 520;
    old=I386HeapAlloc(&scratch,2); if(!old) return 521; old[0]='M'; old[1]=0;
    DirectiveSeed(&cc,&file,&table,&keyword,&bucket,input);
    cc.token=TK_IDENT; cc.cur_str=old; cc.cur_str_len=2; cc.cur_help_idx="Help";
    ok=I386LexDefinePublish(&scratch,&cc,&lines);
    if(ok) {
      passed++; entry=bucket;
      if(entry==&keyword || entry->next!=&keyword || entry->str!=old || cc.cur_str ||
          entry->cnt!=-1 || StrCmp(entry->idx,"Help") || StrCmp(entry->src_link,"FL:Source.HC,1") ||
          I386HeapSize(&scratch,entry->data)!=501) return 522;
      for(i=0;i<500;i++) if(entry->data[i]!=97) return 523;
      if(entry->data[500]) return 524;
      bucket=entry->next;
      if(!I386HashDel(&scratch,entry)) return 525;
    } else {
      failed++;
      if(bucket!=&keyword || cc.cur_str!=old || cc.cur_str_len!=2 || cc.token!=TK_IDENT ||
          scratch.allocations!=1 || I386HeapSize(&scratch,old)!=2 || old[0]!='M' || old[1]) return 526;
      if(!I386HeapFree(&scratch,old)) return 527;
    }
    if(scratch.used || scratch.allocations || !I386HeapValid(&scratch)) return 528;
  }
  if(!failed || !passed) return 529;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"\n;");
  if(!I386LexIncludeCopy(&token_heap,&cc,"Child","#define M 2e0")) return 530;
  if(MacroNext(&cc,&lines)!=59 || cc.lex_include_stk!=&file) return 531;
  entry=HashFind("M",&table,HTT_DEFINE_STR);
  if(!entry || StrCmp(entry->src_link,"FL:Child,1") || StrCmp(entry->data,"2e0") ||
      !DirectiveClear(&cc,&table,&keyword)) return 532;
  if(!I386HeapInit(&scratch,0x70000,32)) return 533;
  DirectiveSeed(&cc,&file,&table,&keyword,&bucket,"#define M 2e0\nM;");
  if(I386LexNext(&scratch,&cc,&token_tables,"Macro",&lines)!=-1 ||
      cc.flags&CCF_NO_DEFINES || bucket!=&keyword || !cc.cur_str || StrCmp(cc.cur_str,"define") ||
      !I386HeapFree(&scratch,cc.cur_str) || scratch.used || scratch.allocations || !I386HeapValid(&scratch)) return 534;
  return 0;
}
