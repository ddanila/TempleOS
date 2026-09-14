//Parser allocations preserve exact payload sizes and survive detached graphs.
U0 ProbeParserMemory(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer)
{
  CI386Task *task=I386TaskSelf;
  CCmpCtrl *cc;
  CCodeMisc *misc;
  CArrayDim *first,*second;
  U8 *value,*detached,*fill,*block,*next,*tiny;
  I64 i,attempt,size,accepted,filled_used,filled_allocations;
  I64 used=heap->used,allocations=heap->allocations,refs=task->lifetime_refs;
  U32 flags=GetRFlags;
  cc=probe->files->control_new("",CCF_DONT_FREE_BUF,"Probe/ParserMemory.HC");
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  if(probe->compiler->parser_alloc(heap,cc,0,TRUE) ||
      !probe->compiler->parser_free(heap,cc,0)) KernelStop;
  value=probe->compiler->parser_alloc(heap,cc,37,TRUE);
  if(!value || I386HeapSize(heap,value)!=37 || probe->compiler->parser_free(heap,outer,value)) KernelStop;
  for(i=0;i<37;i++) if(value[i]) KernelStop;
  if(!probe->compiler->parser_free(heap,cc,value) || probe->compiler->parser_free(heap,cc,value)) KernelStop;
  //Allocation precedes the misc node; graph cleanup must consume its registry entry.
  value=probe->compiler->parser_alloc(heap,cc,8,TRUE);
  misc=probe->compiler->code_misc(heap,cc,CMT_STR_CONST); if(!misc) KernelStop;
  value[0]='P'; misc->str=value; misc->st_len=2;
  if(!probe->compiler->code_discard(heap,cc,0,0) || probe->compiler->parser_free(heap,cc,value)) KernelStop;
  //The opposite order, with a linked payload and a separate detached temporary.
  misc=probe->compiler->code_misc(heap,cc,CMT_ARRAY_DIM); if(!misc) KernelStop;
  first=probe->compiler->parser_alloc(heap,cc,sizeof(CArrayDim),TRUE);
  second=probe->compiler->parser_alloc(heap,cc,sizeof(CArrayDim),TRUE);
  first->next=second; first->cnt=2; second->cnt=3; misc->dim=first;
  detached=probe->compiler->parser_alloc(heap,cc,19,FALSE);
  if(!detached || I386HeapSize(heap,first)!=sizeof(CArrayDim)) KernelStop;
  if(!probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
      task->active_controls!=1 || task->lifetime_refs!=refs || heap->used!=used ||
      heap->allocations!=allocations || !I386HeapValid(heap)) KernelStop;
  for(attempt=0;attempt<2;attempt++) {
    cc=probe->files->control_new("",CCF_DONT_FREE_BUF,"Probe/ParserOutMem.HC");
    if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
    fill=0; accepted=0;
    tiny=I386HeapAlloc(heap,8,FALSE); if(!tiny) KernelStop;
    try {
      for(size=65536;size>=8;size=size/2)
        while(block=I386HeapAlloc(heap,size,FALSE)) { block(U8 **)[0]=fill; fill=block; }
      if(attempt) {
        //Leave room for the eight-byte payload but not its larger tracking record.
        if(!I386HeapFree(heap,tiny)) KernelStop; tiny=0;
      }
      filled_used=heap->used; filled_allocations=heap->allocations;
      probe->compiler->parser_alloc(heap,cc,8,TRUE); KernelStop;
    } catch {
      if(task->except_ch!='OutMem' || heap->used!=filled_used ||
          heap->allocations!=filled_allocations || !I386HeapValid(heap)) KernelStop;
      task->catch_except=TRUE; accepted=1;
      //The exception frame is released after this catch returns.
    }
    if(tiny && !I386HeapFree(heap,tiny)) KernelStop;
    while(fill) { next=fill(U8 **)[0]; if(!I386HeapFree(heap,fill)) KernelStop; fill=next; }
    if(!accepted || !probe->compiler->control_unwind(task,outer) || task->last_cc!=outer ||
        task->active_controls!=1 || task->lifetime_refs!=refs || task->except_top ||
        heap->used!=used || heap->allocations!=allocations || !I386HeapValid(heap) ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  }
  KernelLog("PARSER MEMORY PROBE "); KernelHex(probe->phase); KernelLog("\n");
}
