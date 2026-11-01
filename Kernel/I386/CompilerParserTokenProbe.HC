class CProbeTrackedDirective {
  CI386CompilerProbe *probe;
  CI386Heap *heap;
  I64 calls;
};
class CProbeChangingInclude {
  CI386LexIncludeService *service;
  I64 calls;
};
Bool ProbeChangingInclude(U8 *context,CI386Heap *heap,CCmpCtrl *cc,U8 *name)
{
  CProbeChangingInclude *state=context;
  state->calls++; state->service->push=0;
  return I386LexIncludeCopy(heap,cc,name,"#include \"Again\"",FALSE);
}
I64 ProbeTrackedDirective(U8 *context,CCmpCtrl *cc,I64 keyword)
{//A non-recursive callback can publish its own parser-owned lookahead.
  CProbeTrackedDirective *state=context;
  U8 *value;
  if(keyword!=KW_ASSERT || !cc->cur_str || !I386HeapFree(state->heap,cc->cur_str)) KernelStop;
  cc->cur_str=0;
  value=state->probe->compiler->parser_alloc(state->heap,cc,8,TRUE);
  if(!value) KernelStop;
  value[0]='O'; value[1]='w'; value[2]='n'; value[3]=0;
  cc->cur_str=value; cc->cur_str_len=4; cc->token=TK_IDENT;
  state->calls++;
  return TK_IDENT;
}
//Ownership follows identifiers/strings when the parser clears cur_str to take them.
U0 ProbeParserToken(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CCodeMisc *misc;
  U8 *name,*literal,*fill,*tiny,*block,*next;
  I64 lines=0,attempt,size,accepted;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  CI386LexIncludeService service;
  CProbeTrackedDirective directive;
  CProbeChangingInclude changing;
  cc=probe->files->control_new("Alpha Beta \"xy\" Gamma",CCF_DONT_FREE_BUF,"Probe/ParserToken.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  if(probe->compiler->parser_token(heap,cc,"ParserToken",&lines,probe->disk_include)!=TK_IDENT ||
      StrCmp(cc->cur_str,"Alpha")) KernelStop;
  name=cc->cur_str; cc->cur_str=0;
  if(probe->compiler->parser_token(heap,cc,"ParserToken",&lines,probe->disk_include)!=TK_IDENT ||
      StrCmp(cc->cur_str,"Beta") || StrCmp(name,"Alpha")) KernelStop;
  if(probe->compiler->parser_token(heap,cc,"ParserToken",&lines,probe->disk_include)!=TK_STR ||
      StrCmp(cc->cur_str,"xy")) KernelStop;
  literal=cc->cur_str; cc->cur_str=0;
  misc=probe->compiler->code_misc(heap,cc,CMT_STR_CONST); if(!misc) KernelStop;
  misc->str=literal; misc->st_len=3;
  if(probe->compiler->parser_token(heap,cc,"ParserToken",&lines,probe->disk_include)!=TK_IDENT ||
      StrCmp(cc->cur_str,"Gamma") || StrCmp(literal,"xy") || StrCmp(name,"Alpha")) KernelStop;
  if(!probe->compiler->code_discard(heap,cc,0,0) || probe->compiler->parser_free(heap,cc,literal) ||
      probe->compiler->parser_token(heap,cc,"ParserToken",&lines,probe->disk_include)!=TK_EOF) KernelStop;
  //Alpha was never attached to a completed symbol, while Gamma is still lexer-owned.
  if(!probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
      task->active_controls!=1 || task->lifetime_refs!=refs || heap->used!=used ||
      heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  cc=probe->files->control_new("#assert",CCF_DONT_FREE_BUF,"Probe/ParserTokenCallback.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  directive.probe=probe; directive.heap=heap; directive.calls=0;
  service.context=0; service.push=0; service.directive_context=&directive;
  service.directive=&ProbeTrackedDirective;
  if(probe->compiler->parser_token(heap,cc,"ParserToken",&lines,&service)!=TK_IDENT ||
      directive.calls!=1 || StrCmp(cc->cur_str,"Own")) KernelStop;
  name=cc->cur_str; cc->cur_str=0; cc->cur_str_len=0;
  if(!probe->compiler->parser_free(heap,cc,name) ||
      !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
      task->active_controls!=1 || task->lifetime_refs!=refs || heap->used!=used ||
      heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  cc=probe->files->control_new("#include \"First\"",CCF_DONT_FREE_BUF,"Probe/ParserTokenChange.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  changing.service=&service; changing.calls=0;
  service.context=&changing; service.push=&ProbeChangingInclude;
  service.directive_context=0; service.directive=0; accepted=0;
  try { probe->compiler->parser_token(heap,cc,"ParserToken",&lines,&service); }
  catch { if(task->except_ch=='Compiler') { task->catch_except=TRUE; accepted=1; } }
  if(!accepted || changing.calls!=1 || service.push ||
      !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
      task->active_controls!=1 || task->lifetime_refs!=refs || heap->used!=used ||
      heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  for(attempt=0;attempt<2;attempt++) {
    cc=probe->files->control_new("Keep Next",CCF_DONT_FREE_BUF,"Probe/ParserTokenFail.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    if(!attempt && probe->compiler->parser_token(heap,cc,"ParserToken",&lines,probe->disk_include)!=TK_IDENT) KernelStop;
    tiny=I386HeapAlloc(heap,8,FALSE); if(!tiny) KernelStop;
    fill=0; accepted=0;
    try {
      for(size=65536;size>=8;size=size/2)
        while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
      if(attempt) { if(!I386HeapFree(heap,tiny)) KernelStop; tiny=0; }
      probe->compiler->parser_token(heap,cc,"ParserToken",&lines,probe->disk_include); KernelStop;
    } catch {
      if(!attempt && task->except_ch!='Compiler' || attempt && task->except_ch!='OutMem' ||
          !cc->cur_str || StrCmp(cc->cur_str,"Keep")) KernelStop;
      if(attempt && probe->compiler->parser_free(heap,cc,cc->cur_str)) KernelStop;
      task->catch_except=TRUE; accepted=1;
    }
    if(tiny && !I386HeapFree(heap,tiny)) KernelStop;
    while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    if(!accepted || !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
        task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  }
  KernelLog("PARSER TOKEN PROBE "); KernelHex(probe->phase); KernelLog("\n");
}
