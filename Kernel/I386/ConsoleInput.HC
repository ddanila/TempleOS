class CConsoleExecutionResult {
  I64 diagnostics,last_value;
};
U0 NativeExecutionAnswer(U8 *context,I64 value,CHashClass *type)
{
  CConsoleExecutionResult *result=context;
  no_warn type;
  result->last_value=value;
}
#include "/Kernel/TimeTypes.HH"
F64 NativeExecutionTime(U8 *context)
{//The retained PIT scheduler clock measures elapsed seconds at millisecond resolution.
  U32 flags=I386IrqSave;
  I64 ticks=*console_config->jiffies;
  I386IrqRestore(flags);
  no_warn context;
  return ToF64(ticks)/JIFFY_FREQ;
}
U0 ConsoleAnswer(U8 *context,I64 value,CHashClass *type)
{
  CConsoleExecutionResult *result=context;
  result->last_value=value;
  if(type->ptr_stars_cnt) {
    I386TextWrite(&console_text,"0x"); ConsoleUnsigned(value(U32),16);
  } else if(type->raw_type==RT_F64) ConsoleFloat(value);
  else if(type->raw_type==RT_U64 || type->raw_type==RT_U32 ||
      type->raw_type==RT_U16 || type->raw_type==RT_U8) ConsoleUnsigned(value);
  else ConsoleSigned(value);
  I386TextPut(&console_text,10);
}
U0 ConsoleDiagnostic(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{
  CConsoleExecutionResult *result=context;
  I64 index;
  result->diagnostics++;
  if(!kind && !console_diagnostic_line && cc && cc->lex_include_stk) {
    console_diagnostic_line=cc->last_line_num;
    if(console_diagnostic_line<1)
      console_diagnostic_line=cc->lex_include_stk->line_num;
    index=0;
    if(cc->lex_include_stk->full_name)
      while(index<255 && cc->lex_include_stk->full_name[index]) {
        console_diagnostic_filename[index]=cc->lex_include_stk->full_name[index];
        index++;
      }
    console_diagnostic_filename[index]=0;
  }
  if(kind) I386TextWrite(&console_text,"Warning: ");
  else I386TextWrite(&console_text,"Error: ");
  if(message) I386TextWrite(&console_text,message);
  I386TextPut(&console_text,10);
}
Bool ConsoleSourceResult(U8 *source,U8 *filename,I64 flags,I64 *last_value,
  CDoc *document=NULL,Bool execute_api=FALSE,CLexHashTableContext *hash_context=NULL)
{
  CI386CommandInput input;
  CI386Task *task=I386TaskSelf;
  CI386Task *previous_break;
  CI386TaskSymbols *scope=task->symbol_state;
  U8 *bytes=&input;
  I64 i;
  CConsoleExecutionResult execution;
  Bool accepted=FALSE;
  U32 irq;
  console_diagnostic_line=0; console_diagnostic_filename[0]=0;
  for(i=0;i<sizeof(CI386CommandInput);i++) bytes[i]=0;
  if(!scope || scope->task!=task) KernelStop;
  input.heap=scope->heap; input.types=console_config->types;
  input.files=console_config->files; input.includes=console_config->includes;
  execution.diagnostics=0; execution.last_value=0;
  input.flags=flags; input.source=source; input.filename=filename; input.context=&execution;
  input.document=document;input.inherit_context=execute_api;
  input.hash_context=hash_context;
  if(execute_api)input.answer=&NativeExecutionAnswer;
  else input.answer=&ConsoleAnswer;
  input.execution_time=&NativeExecutionTime;
  input.diagnostic=&ConsoleDiagnostic;
  if(!execute_api)input.inspect_exception=&ConsoleDebugException;
  //Required public-header publication must finish before an interactive target exists.
  irq=I386IrqSave;
  previous_break=console_break_task;
  if(!(flags&CCF_JUST_LOAD)) console_break_task=task;
  I386IrqRestore(irq);
  if(!(flags&CCF_JUST_LOAD)) KernelLog("COMPILER BREAK ready\n");
  try {
    accepted=console_config->compiler->input(&input);
    if(execute_api && input.exception=='OutMem')throw(input.exception,TRUE);
    irq=I386IrqSave; console_break_task=previous_break; I386IrqRestore(irq);
    //A request arriving after the compiler's last checkpoint belongs here.
    I386TaskBreakPoll;
  } catch {
    irq=I386IrqSave; console_break_task=previous_break; I386IrqRestore(irq);
    //Unhandled catches return to the dispatcher, which advances to the caller.
    if(!execute_api || task->except_ch=='Compiler' || task->except_ch=='Break') {
      task->catch_except=TRUE; accepted=FALSE;
      if(!execute_api)I386TextWrite(&console_text,"Exception\n");
      execution.diagnostics++;
    }
  }
  if(!accepted) {
    KernelLog("INPUT REJECT exception ");KernelHex(input.exception);
    KernelLog(" errors ");KernelHex(input.errors);
    KernelLog(" warnings ");KernelHex(input.warnings);KernelLog("\n");
  }
  if(!accepted && !execution.diagnostics && !execute_api) {
    if(input.exception=='OutMem') I386TextWrite(&console_text,"Out of memory\n");
    else I386TextWrite(&console_text,"Compilation failed\n");
  }
  if(last_value) *last_value=execution.last_value;
  return accepted;
}
Bool ConsoleSource(U8 *source,U8 *filename,I64 flags=0)
{ return ConsoleSourceResult(source,filename,flags,0); }
I64 NativeExeDoc(CDoc *doc,I64 flags,Bool *accepted)
{//Compile directly from the locked canonical document in the live task.
  I64 value=0;
  Bool unlock,break_suspended=FALSE,okay=FALSE;
  U32 irq;
  if(accepted) *accepted=FALSE;
  if(!doc || doc->doc_signature!=DOC_SIGNATURE_VAL) return 0;
  unlock=DocLock(doc);
  //The compiler must see a pending keyboard break while this document stays
  //locked. Restore the lock's break state before DocUnlock releases it.
  if(unlock && Bt(&doc->flags,DOCf_BREAK_UNLOCKED)) {
    irq=I386IrqSave;
    if(doc->owning_task==I386TaskSelf &&
        doc->locked_flags&(1<<DOClf_LOCKED) &&
        I386TaskSelf->task_flags&(1<<TASKf_BREAK_LOCKED)) {
      I386TaskSelf->task_flags&=~(1<<TASKf_BREAK_LOCKED);
      break_suspended=TRUE;
    }
    I386IrqRestore(irq);
  }
  try {
    okay=ConsoleSourceResult("",doc->filename.name,flags,&value,doc);
  } catch {
    okay=FALSE;
  }
  if(break_suspended) {
    irq=I386IrqSave;
    I386TaskSelf->task_flags|=1<<TASKf_BREAK_LOCKED;
    I386IrqRestore(irq);
  }
  if(unlock) DocUnlock(doc);
  if(accepted) *accepted=okay;
  if(okay) return value;
  return 0;
}
public Bool DocExe(CDoc *doc,I64 flags=0)
{
  Bool accepted;
  NativeExeDoc(doc,flags,&accepted);
  return accepted;
}
public I64 ExeDoc(CDoc *doc,I64 ccf_flags=0)
{ return NativeExeDoc(doc,ccf_flags,0); }
U0 ConsoleSubmit(U8 *line)
{
  if(ConsoleSource(line,"Console.HC")) KernelLog("COMMAND OK\n");
  else KernelLog("COMMAND ERROR\n");
}

I64 NativeJobSource(U8 *text)
{//Job strings execute in the servant's live compilation scope.
  I64 value=0;
  ConsoleSourceResult(text,"Job.HC",0,&value);
  return value;
}

//Original title policy: a task may lock its title during execution.
U0 NativeExecutionTitleRestore(U8 *title,I64 title_src)
{
  if(Fs->title_src!=TTS_LOCKED_CONST) {
    Fs->title_src=title_src;StrCpy(Fs->task_title,title);
  }
  Free(title);
}
I64 ExePutS(U8 *buf,U8 *filename=NULL,I64 flags=0,
  CLexHashTableContext *htc=NULL)
{
  I64 value=0,title_src=Fs->title_src;
  U8 *title=StrNew(Fs->task_title);
  Bool accepted=FALSE;
  try {accepted=ConsoleSourceResult(buf,filename,flags,&value,NULL,TRUE,htc);}
  catch {NativeExecutionTitleRestore(title,title_src);}
  NativeExecutionTitleRestore(title,title_src);
  if(flags&CCF_JUST_LOAD)return accepted;
  if(!accepted)return 0;
  return value;
}
#include "/Compiler/ExePrintCore.HC"
