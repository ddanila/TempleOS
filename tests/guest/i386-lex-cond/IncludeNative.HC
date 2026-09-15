#include "T:/IncludeSources.HC"
class CIncludeTestState {
  I64 calls,used,allocations;
  U8 snapshot[sizeof(CCmpCtrl)];
};
CIncludeTestState include_state;
CI386LexIncludeService include_service;
Bool IncludePush(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name)
{
  CIncludeTestState *state=context;
  U8 *source=IncludeText(name),*bytes=cc;
  I64 i;
  state->calls++;
  for(i=0;i<sizeof(CCmpCtrl);i++) state->snapshot[i]=bytes[i];
  state->used=heap->used; state->allocations=heap->allocations;
  if(!source) return FALSE;
  return I386LexIncludeCopy(heap,cc,name,source,FALSE);
}
U0 IncludePrepare()
{
  include_state.calls=0;
  include_service.context=&include_state; include_service.push=&IncludePush;
  include_service.directive_context=0; include_service.directive=0;
}
Bool IncludeLoads(I64 count) { return include_state.calls==count; }
I64 IncludeNext(CCmpCtrl *cc,I64 *lines)
{
  return I386LexNextWithIncludes(&token_heap,cc,&token_tables,"Macro",lines,&include_service);
}
Bool IncludeSymbolFree(CHashSrcSym *entry) { return I386HashDel(&token_heap,entry); }
#include "T:/Includes.HC"
I64 IncludeFailureTest()
{
  CCmpCtrl cc; CLexFile file; I64 lines=0,i;
  U8 *bytes=&cc;
  IncludePrepare;
  IdentSeed(&cc,&file,"#include \"T:/Missing.HC\" 9"); cc.htc.hash_table_lst=keywords.table;
  if(IncludeNext(&cc,&lines)!=-1 || include_state.calls!=1 || cc.lex_include_stk!=&file ||
      token_heap.used!=include_state.used || token_heap.allocations!=include_state.allocations) return 180;
  for(i=0;i<sizeof(CCmpCtrl);i++) if(bytes[i]!=include_state.snapshot[i]) return 181;
  if(IncludeNext(&cc,&lines)!=TK_I64 || cc.cur_i64!=9 || !ConditionalFree(&cc)) return 182;
  IdentSeed(&cc,&file,"#include \"T:/First.HC\" 9"); cc.htc.hash_table_lst=keywords.table;
  if(ConditionalNext(&cc,&lines)!=-4 || StrCmp(cc.cur_str,"include") || !ConditionalFree(&cc)) return 183;
  IdentSeed(&cc,&file,"#include \"T:/First.HC\" 9"); cc.htc.hash_table_lst=keywords.table;
  include_service.push=0;
  if(IncludeNext(&cc,&lines)!=-4 || StrCmp(cc.cur_str,"include") || !ConditionalFree(&cc)) return 184;
  IncludePrepare;
  IdentSeed(&cc,&file,"#include '123456789' 9"); cc.htc.hash_table_lst=keywords.table;
  if(IncludeNext(&cc,&lines)!=-5 || include_state.calls || !ConditionalFree(&cc)) return 185;
  IdentSeed(&cc,&file,"#include \"T:/First.HC\"",CCF_KEEP_SIGN_NUM); cc.htc.hash_table_lst=keywords.table;
  if(IncludeNext(&cc,&lines)!=35 || include_state.calls || !ConditionalFree(&cc)) return 186;
  return 0;
}
