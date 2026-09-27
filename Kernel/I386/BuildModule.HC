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
  I64 source_bytes,module_bytes=0,raw_type,commands=0,exception=0,stage=0;
  Bool entered=FALSE,compiled=FALSE,clean=TRUE;
  if(!console_config || !task || !source_path || !target_path ||
      !(scope=task->symbol_state) || scope->task!=task ||
      !(heap=scope->heap)) return -1;
  compiler=console_config->compiler; boundary=task->last_cc;
  source=(*console_config->files->read)(heap,source_path,&source_bytes,0,0);
  if(!source || source_bytes<1 || source_bytes>1048576) goto build_module_done;
  stage=1;
  try {
    cc=(*console_config->files->control_new)(source,
      CCF_DONT_FREE_BUF|CCF_AOT_COMPILE|CCF_MODULE_SOURCE,source_path);
    if(!cc) throw('OutMem',TRUE);
    if(!(*compiler->control_enter)(heap,cc,0,0)) {
      (*compiler->control_del)(heap,cc,0,0); cc=0;
      throw('OutMem',TRUE);
    }
    entered=TRUE;
    stage=2;
    symbols=(*compiler->frontend)(heap,cc,console_config->types,
      console_config->includes);
    if(!symbols || !(*compiler->frontend_private_defines)(symbols))
      throw('OutMem',TRUE);
    stage=3;
    declarations=symbols->declarations; expression=declarations->expression;
    (*expression->lex)(expression->context,cc);
    while(cc->token!=TK_EOF) {
      if(++commands>4096) throw('Compiler',TRUE);
      if(!(commands&15)) {
        KernelLog("BUILD MODULE PROGRESS "); KernelHex(commands); KernelLog(" ");
        if(cc->lex_include_stk && cc->lex_include_stk->full_name)
          KernelLog(cc->lex_include_stk->full_name);
        KernelLog(" "); KernelHex(cc->last_line_num);
        KernelLog(" "); KernelHex(heap->used); KernelLog("\n");
      }
      if(336<=commands<400) {
        KernelLog("BUILD MODULE COMMAND START "); KernelHex(commands); KernelLog(" ");
        if(cc->lex_include_stk && cc->lex_include_stk->full_name)
          KernelLog(cc->lex_include_stk->full_name);
        KernelLog(" "); KernelHex(cc->last_line_num); KernelLog("\n");
      }
      code=(*compiler->command)(heap,cc,symbols,&raw_type);
      if(336<=commands<400) {
        KernelLog("BUILD MODULE COMMAND DONE "); KernelHex(commands); KernelLog("\n");
      }
      if(code && !(cc->flags&CCF_HAS_MISC_DATA))
        (*declarations->release)(declarations->context,code);
    }
    if(cc->error_cnt) throw('Compiler',TRUE);
    stage=4;
    module_bytes=(*compiler->program_pack_unit)(symbols,0,0);
    stage=5;
    if(module_bytes<32 || module_bytes>4194304 ||
        !(module=I386HeapAlloc(heap,module_bytes))) throw('Compiler',TRUE);
    stage=6;
    if((*compiler->program_pack_unit)(symbols,module,module_bytes)!=module_bytes)
      throw('Compiler',TRUE);
    stage=7;
    compiled=TRUE;
  } catch {
    exception=task->except_ch;
    task->catch_except=TRUE;
    if(cc && cc->lex_include_stk) {
      KernelLog("BUILD MODULE SOURCE ");
      if(cc->lex_include_stk->full_name)
        KernelLog(cc->lex_include_stk->full_name);
      KernelLog(" "); KernelHex(cc->last_line_num);
      KernelLog(" "); KernelHex(cc->error_cnt); KernelLog(" "); KernelHex(cc->flags); KernelLog("\n");
    }
  }
  if(entered && !(*compiler->control_unwind)(task,boundary)) clean=FALSE;
  if(compiled && clean) stage=8;
  if(compiled && clean &&
      !(*console_config->files->write)(target_path,module,module_bytes,0))
    compiled=FALSE;
  if(compiled) stage=9;
build_module_done:
  if(module && !I386HeapFree(heap,module)) clean=FALSE;
  if(source && !I386HeapFree(heap,source)) clean=FALSE;
  if(!compiled || !clean) {
    KernelLog("BUILD MODULE REJECT "); KernelHex(stage); KernelLog(" ");
    KernelHex(module_bytes); KernelLog(" "); KernelHex(exception); KernelLog("\n");
  }
  if(exception && exception!='Compiler' && exception!='OutMem') throw(exception,TRUE);
  if(compiled && clean) return module_bytes;
  return -1;
}
