//Included after lexer, native control and parser allocation implementations.
#include "/Compiler/I386/ParserToken.HH"
class CI386ParserLexWatch {
  CI386CmpCtrl *owned;
  CI386LexIncludeService *service;
  CI386LexIncludeService *watched;
};
extern Bool I386ParserLexPush(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name);
extern I64 I386ParserLexDirective(U8 *context,CCmpCtrl *cc,I64 keyword);
U0 I386ParserLexRefresh(CI386ParserLexWatch *watch)
{
  if(watch->service->push) watch->watched->push=&I386ParserLexPush;
  else watch->watched->push=0;
  if(watch->service->directive) watch->watched->directive=&I386ParserLexDirective;
  else watch->watched->directive=0;
}
U0 I386ParserLexTouch(CI386ParserLexWatch *watch)
{
  U32 irq=I386IrqSave;
  if(watch->owned->token_epoch!=0xFFFFFFFF) watch->owned->token_epoch++;
  I386IrqRestore(irq);
}
Bool I386ParserLexPush(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name)
{
  CI386ParserLexWatch *watch=context;
  Bool result;
  I386ParserLexTouch(watch);
  result=(*watch->service->push)(watch->service->context,heap,cc,name);
  I386ParserLexRefresh(watch); return result;
}
I64 I386ParserLexDirective(U8 *context,CCmpCtrl *cc,I64 keyword)
{
  CI386ParserLexWatch *watch=context;
  I64 result;
  I386ParserLexTouch(watch);
  result=(*watch->service->directive)(watch->service->directive_context,cc,keyword);
  I386ParserLexRefresh(watch); return result;
}
I64 I386ParserToken(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,
  I64 *compiled_lines,CI386LexIncludeService *includes)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record,*pending=0,*current=0;
  CI386ParserLexWatch watch;
  CI386LexIncludeService watched,*active=includes;
  I64 token;
  U32 epoch,irq=I386IrqSave;
  if(!I386CmpCodeOwner(heap,cc) || !compiled_lines ||
      cc->cur_str && !I386HeapKnownAtLeast(heap,cc->cur_str,1)) {
    I386IrqRestore(irq); return -1;
  }
  if(owned->token_epoch!=0xFFFFFFFF) owned->token_epoch++;
  epoch=owned->token_epoch;
  if(includes) {
    watch.owned=owned; watch.service=includes; watch.watched=&watched;
    watched.context=&watch; watched.directive_context=&watch;
    I386ParserLexRefresh(&watch);
    active=&watched;
  }
  if(cc->cur_str) {
    for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
      if(record->allocation==cc->cur_str) { pending=record; break; }
    //The raw lexer may replace/free its current string. Keep the tracking slot
    //owned, but let final lexer cleanup own the current payload during this call.
    if(pending) pending->allocation=0;
  }
  I386IrqRestore(irq);
  token=I386RuntimeLexIncludes(heap,cc,macro_filename,compiled_lines,active);
  if(token==I386_LEX_OUT_OF_MEMORY) throw('OutMem',TRUE);
  if(token<0) { cc->error_cnt++; throw('Compiler',TRUE); }
  irq=I386IrqSave;
  if(cc->cur_str) {
    //A parser-backed directive may recurse through this adapter. Its final
    //lookahead is already tracked; do not give that payload two owners.
    //A recursive parser call or external include callback can publish the final
    //lookahead. At epoch saturation, always retain the full walk.
    if(epoch==0xFFFFFFFF || epoch!=owned->token_epoch) {
      for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
        if(record->allocation==cc->cur_str) { current=record; break; }
    }
#ifdef I386_TOKEN_OWNERSHIP_AUDIT
    else {
      for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
        if(record->allocation==cc->cur_str) { I386IrqRestore(irq); throw('TokOwn',TRUE); }
    }
#endif
    if(current) {
      if(pending && pending!=current) {
        pending->last->next=pending->next; pending->next->last=pending->last;
        I386HeapFree(heap,pending);
      }
      pending=current;
    }
    if(!pending) {
      pending=I386HeapAllocHigh(heap,offset(CI386ParserAllocation.requested),TRUE);
      if(!pending) { I386IrqRestore(irq); throw('OutMem',TRUE); }
      pending->next=&owned->parser_next; pending->last=owned->parser_last;
      pending->last->next=pending; owned->parser_last=pending;
    }
    pending->allocation=cc->cur_str;
  } else if(pending) {
    pending->last->next=pending->next; pending->next->last=pending->last;
    if(!I386HeapFree(heap,pending)) { I386IrqRestore(irq); throw('Compiler',TRUE); }
  }
  I386IrqRestore(irq); return token;
}
