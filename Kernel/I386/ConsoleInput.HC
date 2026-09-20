U0 ConsoleAnswer(U8 *context,I64 value,CHashClass *type)
{
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
  I64 *count=context;
  (*count)++;
  if(kind) I386TextWrite(&console_text,"Warning: ");
  else I386TextWrite(&console_text,"Error: ");
  if(message) I386TextWrite(&console_text,message);
  I386TextPut(&console_text,10);
}
Bool ConsoleSource(U8 *source,U8 *filename,I64 flags=0)
{
  CI386CommandInput input;
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  U8 *bytes=&input;
  I64 i,diagnostics=0;
  Bool accepted=FALSE;
  U32 irq;
  for(i=0;i<sizeof(CI386CommandInput);i++) bytes[i]=0;
  if(!scope || scope->task!=task) KernelStop;
  input.heap=scope->heap; input.types=console_config->types;
  input.files=console_config->files; input.includes=console_config->includes;
  input.flags=flags; input.source=source; input.filename=filename; input.context=&diagnostics;
  input.answer=&ConsoleAnswer; input.diagnostic=&ConsoleDiagnostic;
  //Required public-header publication must finish before an interactive target exists.
  irq=I386IrqSave;
  if(!(flags&CCF_JUST_LOAD)) console_break_task=task;
  I386IrqRestore(irq);
  try {
    accepted=console_config->compiler->input(&input);
    irq=I386IrqSave; console_break_task=0; I386IrqRestore(irq);
    //A request arriving after the compiler's last checkpoint belongs here.
    I386TaskBreakPoll;
  } catch {
    irq=I386IrqSave; console_break_task=0; I386IrqRestore(irq);
    task->catch_except=TRUE; accepted=FALSE;
    I386TextWrite(&console_text,"Exception\n"); diagnostics++;
  }
  if(!accepted && !diagnostics) {
    if(input.exception=='OutMem') I386TextWrite(&console_text,"Out of memory\n");
    else I386TextWrite(&console_text,"Compilation failed\n");
  }
  return accepted;
}
U0 ConsoleSubmit(U8 *line)
{
  if(ConsoleSource(line,"Console.HC")) KernelLog("COMMAND OK\n");
  else KernelLog("COMMAND ERROR\n");
}
