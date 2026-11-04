U8 *ProbeProgramRead(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *cc,
  CPrsSymbolServices *symbols,Bool execute=TRUE)
{
  CPrsDeclarationServices *d=symbols->declarations;
  CPrsExpressionServices *e=d->expression;
  U8 *code,*last=0;
  I64 type,count=0;
  e->report=&ProbeExpressionReport; d->types->report=&ProbeExpressionReport;
  e->lex(e->context,cc);
  while(cc->token!=TK_EOF) {
    if(++count>128) KernelStop;
    code=probe->compiler->command(heap,cc,symbols,&type);
    if(code) {
      if(execute) d->execute(d->context,code);
      if(cc->flags&CCF_HAS_MISC_DATA) last=code;
      else d->release(d->context,code);
    }
  }
  return last;
}
I64 ProbeProgramUse(CI386CompilerProbe *probe,CI386Heap *heap,CCmpCtrl *outer,U8 *source)
{
  CCmpCtrl *cc=probe->files->control_new(source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,"Probe/ProgramUse.HC");
  CPrsSymbolServices *symbols;
  CPrsDeclarationServices *d;
  CPrsExpressionServices *e;
  U8 *code;
  I64 type,value=0;
  if(!cc || !probe->compiler->control_enter(heap,cc,0,0)) KernelStop;
  symbols=probe->compiler->frontend(heap,cc,probe->internal_types,probe->disk_include);
  if(!symbols) KernelStop;
  d=symbols->declarations; e=d->expression;
  e->lex(e->context,cc);
  while(cc->token!=TK_EOF) {
    code=probe->compiler->command(heap,cc,symbols,&type);
    if(code) { value=d->execute(d->context,code); d->release(d->context,code); }
  }
  if(!probe->compiler->control_unwind(I386TaskSelf,outer)) KernelStop;
  return value;
}
