#include "/Kernel/I386/TaskCompiler.HH"
#include "/Kernel/I386/Cpu.HH"
Bool I386TaskCompilerInit(CI386TaskCompilerConfig *config,CI386CompilerServices *compiler,
  U8 *tmp_filename,U32 *alpha_numeric,U32 *alpha_numeric_no_at)
{
  U32 flags=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  Bool result=FALSE;
  if(config && !config->compiler && compiler && compiler->version==I386_COMPILER_SERVICES_VERSION &&
      compiler->bytes==sizeof(CI386CompilerServices) && compiler->control_new && compiler->control_del &&
      compiler->control_enter && compiler->control_leave && compiler->control_drain && compiler->control_unwind && compiler->code_add && compiler->code_misc && compiler->code_discard &&
      compiler->code_save && compiler->code_push && compiler->code_pop && compiler->code_free && compiler->code_append && compiler->code_retire &&
      tmp_filename && alpha_numeric && alpha_numeric_no_at && task && task->owner &&
      task==task->owner->root && task==task->owner->current) {
    config->tmp_filename=tmp_filename; config->alpha_numeric=alpha_numeric;
    config->alpha_numeric_no_at=alpha_numeric_no_at; config->compiler=compiler;
    result=TRUE;
  }
  I386IrqRestore(flags); return result;
}
CCmpCtrl *I386TaskCmpCtrlNew(CI386TaskCompilerConfig *config,U8 *buffer=0,I64 flags=0,U8 *filename=0)
{
  U32 irq=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope;
  CI386TaskFiles *borrow;
  CI386FileVolumes *volumes;
  CFilePathContext paths;
  CCmpCtrl *result=0;
  U8 *name;
  U32 *bitmap;
  if(!config || !config->compiler || config->compiler->version!=I386_COMPILER_SERVICES_VERSION ||
      config->compiler->bytes!=sizeof(CI386CompilerServices) || !config->compiler->control_new || !task ||
      !(scope=task->symbol_state) || scope->task!=task || scope->table!=task->hash_table ||
      scope->signature!=I386_TASK_SYMBOLS_MAGIC || !config->tmp_filename ||
      !config->alpha_numeric || !config->alpha_numeric_no_at) goto task_control_done;
  name=config->tmp_filename;
  if(filename) {
    borrow=I386TaskFilesBorrow(task,&paths,&volumes);
    if(!borrow) goto task_control_done;
    name=I386FileNameAbs(scope->heap,&paths,filename);
    if(!I386TaskFilesRelease(borrow)) {
      if(name) I386HeapFree(scope->heap,name);
      goto task_control_done;
    }
    if(!name) goto task_control_done;
  }
  bitmap=config->alpha_numeric;
  if(flags&CCF_KEEP_AT_SIGN) bitmap=config->alpha_numeric_no_at;
  result=config->compiler->control_new(scope->heap,buffer,flags,name,task->hash_table,bitmap,task);
  if(filename) I386HeapFree(scope->heap,name);
task_control_done:
  I386IrqRestore(irq); return result;
}
