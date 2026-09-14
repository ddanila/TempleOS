//Included after lexer, native control and parser allocation implementations.
#include "/Compiler/I386/ParserToken.HH"
I64 I386ParserToken(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,
  I64 *compiled_lines,CI386LexIncludeService *includes)
{
  CI386CmpCtrl *owned=cc;
  CI386ParserAllocation *record,*pending=0;
  I64 token;
  U32 irq=I386IrqSave;
  if(!I386CmpCodeOwner(heap,cc) || !compiled_lines ||
      cc->cur_str && I386HeapSize(heap,cc->cur_str)<1) {
    I386IrqRestore(irq); return -1;
  }
  if(cc->cur_str) {
    for(record=owned->parser_next;record!=&owned->parser_next;record=record->next)
      if(record->allocation==cc->cur_str) { pending=record; break; }
    //The raw lexer may replace/free its current string. Keep the tracking slot
    //owned, but let final lexer cleanup own the current payload during this call.
    if(pending) pending->allocation=0;
  }
  I386IrqRestore(irq);
  token=I386RuntimeLexIncludes(heap,cc,macro_filename,compiled_lines,includes);
  if(token<0) { cc->error_cnt++; throw('Compiler',TRUE); }
  irq=I386IrqSave;
  if(cc->cur_str) {
    if(!pending) {
      pending=I386HeapAlloc(heap,sizeof(CI386ParserAllocation),TRUE);
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
