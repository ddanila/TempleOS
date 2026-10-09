#include "/Kernel/I386/ModuleStageCheck.HC"
Bool I386BuildModuleBinding(CI386ModuleBinding *binding,U8 *name)
{
  I64 i=0;
  if(binding->kind!=I386_MODULE_EXPORT || !binding->address || !binding->name)return FALSE;
  while(name[i] && binding->name[i]==name[i])i++;
  return !name[i] && !binding->name[i];
}
//Compile one on-disk HolyC source unit to a relocatable T32M on a mounted drive.
//The private compilation control is unwound before publishing the file.
I64 I386BuildModuleCore(CI386BuildContext *build_config,U8 *source_path,U8 *target_path,Bool boot_module=FALSE)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope;
  CI386Heap *heap;
  CI386CompilerServices *compiler;
  CI386ModuleBinding binding;
  CI386ModuleStage *output_stage=0;
  U8 scratch[512];
  CI386ModuleStage *(*stage_new)(U8 *target,I64 bytes);
  Bool (*stage_cleanup)(U8 *context);
  Bool (*module_valid)(U8 *module,I64 bytes);
  Bool (*module_publish)(CI386ModuleStage *unit,U8 *target);
  Bool (*valid_parts)(CI386ModuleHeader *h,CI386ModuleRecord *records,
    U8 *strings,I64 size,U8 (*code)(U8 *context,U32 offset),U8 *context);
  CI386ModuleHeader staged_header;
  U8 *metadata=0;
  I64 metadata_bytes;
  I64 (*unit_write)(CPrsSymbolServices *symbols,
    I64 (*sink)(U8 *context,U32 offset,U8 *buffer,U32 bytes),U8 *context,
    U8 *scratch,I64 scratch_bytes);
  CPrsSymbolServices *symbols;
  CPrsDeclarationServices *declarations;
  CPrsExpressionServices *expression;
  CCmpCtrl *boundary,*cc=0;
  U8 *source=0,*module=0,*code,*target_absolute=0;
  I64 source_bytes,module_bytes=0,raw_type,commands=0,exception=0,stage=0;
  Bool entered=FALSE,compiled=FALSE,clean=TRUE,staged=FALSE;
  I64 written;
  if(!build_config || !task || !source_path || !target_path ||
      !(scope=task->symbol_state) || scope->task!=task ||
      !(heap=scope->heap)) return -1;
  compiler=build_config->compiler; boundary=task->last_cc;
  if(!build_config->files->export_at(1,&binding) ||
      !I386BuildModuleBinding(&binding,"I386TaskModuleStageNew"))return -1;
  stage_new=binding.address;
  if(!build_config->files->export_at(2,&binding) ||
      !I386BuildModuleBinding(&binding,"I386TaskModuleStageCleanup"))return -1;
  stage_cleanup=binding.address;
  if(!build_config->files->export_at(3,&binding) ||
      !I386BuildModuleBinding(&binding,"I386TaskModulePublish"))return -1;
  module_publish=binding.address;
  if(!compiler->export_at(1,&binding) || !I386BuildModuleBinding(&binding,"I386ModuleValid"))return -1;
  module_valid=binding.address;
  if(!compiler->export_at(2,&binding) ||
      !I386BuildModuleBinding(&binding,"I386FrontendModuleWriteUnit"))return -1;
  unit_write=binding.address;
  if(!compiler->export_at(3,&binding) ||
      !I386BuildModuleBinding(&binding,"I386ModuleValidParts"))return -1;
  valid_parts=binding.address;
  target_absolute=(*build_config->files->name_abs)(heap,target_path,0);
  if(!target_absolute)return -1;
  source=(*build_config->files->read)(heap,source_path,&source_bytes,0,0);
  if(!source || source_bytes<1 || source_bytes>1048576) goto build_module_done;
  stage=1;
  output_stage=(*stage_new)(target_absolute,0);
  if(!output_stage)goto build_module_done;
  try {
    cc=(*build_config->files->control_new)(source,
      CCF_DONT_FREE_BUF|CCF_AOT_COMPILE|CCF_MODULE_SOURCE|
      (boot_module*CCF_BOOT_MODULE),source_path);
    if(!cc) throw('OutMem',TRUE);
    if(!(*compiler->control_enter)(heap,cc,0,0)) {
      (*compiler->control_del)(heap,cc,0,0); cc=0;
      throw('OutMem',TRUE);
    }
    entered=TRUE;
    stage=2;
    symbols=(*compiler->frontend)(heap,cc,build_config->types,
      build_config->includes);
    if(!symbols || !(*compiler->frontend_private_defines)(symbols) ||
        !(*compiler->frontend_bind_files)(symbols,build_config->files))
      throw('OutMem',TRUE);
    stage=3;
    //The resident memory provider binds this to managed Yield: pending public
    //Kill can retire the task and unwind its registered compiler/file owners.
    if(!I386SchedYield(task->owner))throw('Task',TRUE);
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
      //Only yield between complete commands, with no borrowed parser frame or
      //RedSea lease active. Keep the private control live for task cleanup.
      if(!I386SchedYield(task->owner))throw('Task',TRUE);
    }
    if(cc->error_cnt) throw('Compiler',TRUE);
    stage=4;
    module_bytes=(*compiler->program_pack_unit)(symbols,0,0);
    stage=5;
    if(module_bytes<32 || module_bytes>4194304)throw('Compiler',TRUE);
    if(!(*output_stage->reserve)(output_stage,module_bytes))throw('Compiler',TRUE);
    stage=6;
    written=(*unit_write)(symbols,output_stage->emit,output_stage,scratch,sizeof(scratch));
    if(written==module_bytes && (*output_stage->seal)(output_stage))staged=TRUE;
    else if(!written && !output_stage->written && output_stage->phase==I386_STAGE_OPEN && module_bytes<=65536) {
      //Small top-level assembly bundles retain their contiguous packing path.
      if(!(*stage_cleanup)(output_stage))throw('Compiler',TRUE);
      output_stage=0;
      module=I386HeapAlloc(heap,module_bytes);
      if(!module || (*compiler->program_pack_unit)(symbols,module,module_bytes)!=module_bytes)
        throw('Compiler',TRUE);
    } else throw('Compiler',TRUE);
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
  if(compiled && clean) {
    stage=8;
    if(source) {
      if(!I386HeapFree(heap,source))clean=FALSE;
      else source=0;
    }
    if(staged && clean) {
      if(!(*output_stage->unwound)(output_stage,TRUE))compiled=FALSE;
      if(compiled) {
        metadata_bytes=I386ModuleStageMetadataSize(output_stage,&staged_header);
        if(metadata_bytes<0 || !(metadata=I386HeapAlloc(heap,metadata_bytes+!metadata_bytes)) ||
            !I386ModuleStageValid(output_stage,metadata,metadata_bytes,valid_parts))compiled=FALSE;
        if(metadata) {
          if(!I386HeapFree(heap,metadata))clean=FALSE;
          else metadata=0;
        }
      }
      if(compiled && clean && !(*module_publish)(output_stage,target_absolute))compiled=FALSE;
    }
    if(!staged && compiled && clean && !(*module_valid)(module,module_bytes))compiled=FALSE;
  }
  if(output_stage) {
    if(!(*stage_cleanup)(output_stage))clean=FALSE;
    output_stage=0;
  }
  if(!staged && compiled && clean &&
      !(*build_config->files->write)(target_absolute,module,module_bytes,0))
    compiled=FALSE;
  if(compiled) stage=9;
build_module_done:
  if(metadata && !I386HeapFree(heap,metadata))clean=FALSE;
  if(target_absolute && !I386HeapFree(heap,target_absolute))clean=FALSE;
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
