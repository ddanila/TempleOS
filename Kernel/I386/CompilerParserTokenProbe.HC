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
