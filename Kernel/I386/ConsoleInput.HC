class CConsoleExecutionResult {
  I64 diagnostics,last_value;
};
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
  CDoc *document=NULL)
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
  input.document=document;
  input.answer=&ConsoleAnswer; input.diagnostic=&ConsoleDiagnostic;
  //Required public-header publication must finish before an interactive target exists.
  irq=I386IrqSave;
  previous_break=console_break_task;
  if(!(flags&CCF_JUST_LOAD)) console_break_task=task;
  I386IrqRestore(irq);
  if(!(flags&CCF_JUST_LOAD)) KernelLog("COMPILER BREAK ready\n");
  try {
    accepted=console_config->compiler->input(&input);
    irq=I386IrqSave; console_break_task=previous_break; I386IrqRestore(irq);
    //A request arriving after the compiler's last checkpoint belongs here.
    I386TaskBreakPoll;
  } catch {
    irq=I386IrqSave; console_break_task=previous_break; I386IrqRestore(irq);
    task->catch_except=TRUE; accepted=FALSE;
    I386TextWrite(&console_text,"Exception\n"); execution.diagnostics++;
  }
  if(!accepted && !execution.diagnostics) {
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
