//Compile one on-disk HolyC source unit to a relocatable T32M on a mounted drive.
//The private compilation control is unwound before publishing the file.
public I64 I386BuildModule(U8 *source_path,U8 *target_path)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope;
  CI386Heap *heap;
  CI386CompilerServices *compiler;
  CPrsSymbolServices *symbols;
  CPrsDeclarationServices *declarations;
  CPrsExpressionServices *expression;
  CCmpCtrl *boundary,*cc=0;
  U8 *source=0,*module=0,*code;
  I64 source_bytes,module_bytes=0,raw_type,commands=0,exception=0;
  Bool entered=FALSE,compiled=FALSE,clean=TRUE;
  if(!console_config || !task || !source_path || !target_path ||
      !(scope=task->symbol_state) || scope->task!=task ||
      !(heap=scope->heap)) return -1;
  compiler=console_config->compiler; boundary=task->last_cc;
  source=(*console_config->files->read)(heap,source_path,&source_bytes,0,0);
  if(!source || source_bytes<1 || source_bytes>1048576) goto build_module_done;
  try {
    cc=(*console_config->files->control_new)(source,
      CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,source_path);
    if(!cc) throw('OutMem',TRUE);
    if(!(*compiler->control_enter)(heap,cc,0,0)) {
      (*compiler->control_del)(heap,cc,0,0); cc=0;
      throw('OutMem',TRUE);
    }
    entered=TRUE;
    symbols=(*compiler->frontend)(heap,cc,console_config->types,
      console_config->includes);
    if(!symbols || !(*compiler->frontend_private_defines)(symbols))
      throw('OutMem',TRUE);
    declarations=symbols->declarations; expression=declarations->expression;
    (*expression->lex)(expression->context,cc);
    while(cc->token!=TK_EOF) {
      if(++commands>4096) throw('Compiler',TRUE);
      code=(*compiler->command)(heap,cc,symbols,&raw_type);
      if(code && !(cc->flags&CCF_HAS_MISC_DATA))
        (*declarations->release)(declarations->context,code);
    }
    if(cc->error_cnt) throw('Compiler',TRUE);
    module_bytes=(*compiler->program_pack_unit)(symbols,0,0);
    if(module_bytes<32 || module_bytes>1048576 ||
        !(module=I386HeapAlloc(heap,module_bytes)) ||
        (*compiler->program_pack_unit)(symbols,module,module_bytes)!=module_bytes)
      throw('Compiler',TRUE);
    compiled=TRUE;
  } catch {
    exception=task->except_ch;
    task->catch_except=TRUE;
  }
  if(entered && !(*compiler->control_unwind)(task,boundary)) clean=FALSE;
  if(compiled && clean &&
      !(*console_config->files->write)(target_path,module,module_bytes,0))
    compiled=FALSE;
build_module_done:
  if(module && !I386HeapFree(heap,module)) clean=FALSE;
  if(source && !I386HeapFree(heap,source)) clean=FALSE;
  if(exception && exception!='Compiler' && exception!='OutMem') throw(exception,TRUE);
  if(compiled && clean) return module_bytes;
  return -1;
}
