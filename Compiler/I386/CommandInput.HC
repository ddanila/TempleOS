//Only active controls are owned by this catch/unwind boundary. Other lifetime
//references (for example a borrowed file context) must return normally first.
U0 I386CommandInputCheckpoint(CI386Task *task,Bool *interrupted)
{
  U32 irq=I386IrqSave;
  Bool ready=(task->task_flags&(1<<TASKf_PENDING_BREAK)) &&
    !(task->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_BREAK_TO_SHIFT_ESC)) &&
    !task->wait && !task->blocked && !task->io_locks && !task->compiler_busy &&
    !task->compiler_cleanup_failed && !task->messages &&
    task->lifetime_refs==task->active_controls;
  if(ready) *interrupted=TRUE;
  I386IrqRestore(irq);
  if(ready) throw('Break',TRUE);
}
//One submitted buffer: compile/execute, publish, then unwind its private control.
Bool I386CommandInput(CI386CommandInput *input)
{
  CI386Task *task=I386TaskSelf;
  CI386Heap *heap;
  CCmpCtrl *boundary,*cc=0;
  CI386Frontend *state;
  CPrsSymbolServices *symbols;
  CI386FrontendCode *output;
  CI386CmpCtrl *owned;
  U8 *code;
  I64 raw_type,value;
  Bool accepted=FALSE,raised=FALSE,interrupted=FALSE,unwound;
  U32 irq;
  if(!input) return FALSE;
  input->commands=0; input->answers=0; input->errors=0;
  input->warnings=0; input->exception=0;
  heap=input->heap;
  if(!task || !I386CmpTaskOwnerValid(task,heap,task->hash_table) || !input->source ||
      !input->filename || !input->types || !input->files ||
      input->files->version!=I386_FILE_SERVICES_VERSION ||
      input->files->bytes!=sizeof(CI386FileServices) || !input->files->control_new ||
      input->flags&~(CCF_JUST_LOAD|I386_INPUT_ATOMIC_DEFINES)) return FALSE;
  boundary=task->last_cc;
  try {
    I386CommandInputCheckpoint(task,&interrupted);
    cc=input->files->control_new(input->source,CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,input->filename);
    if(!cc) I386CommandInputCheckpoint(task,&interrupted);
    if(cc) {
      if(!I386CmpCtrlEnter(heap,cc)) {
        I386CmpCtrlDel(heap,cc); cc=0;
      } else {
        symbols=I386FrontendServices(heap,cc,input->types,input->includes);
        if(!symbols) throw('OutMem',TRUE);
        state=symbols->context; state->files=input->files;
        if(input->flags&I386_INPUT_ATOMIC_DEFINES) {
          owned=cc;
          owned->private_defines=I386HashTableNew(heap,32);
          if(!owned->private_defines) throw('OutMem',TRUE);
          state->defines=owned->private_defines;
          state->defines->next=state->parent; state->table->next=state->defines;
          cc->htc.define_hash_table=state->defines;
        }
        state->diagnostic_context=input->context; state->diagnostic=input->diagnostic;
        I386CommandInputCheckpoint(task,&interrupted);
        I386FrontendLex(state,cc);
        I386CommandInputCheckpoint(task,&interrupted);
        while(cc->token!=TK_EOF) {
          I386CommandInputCheckpoint(task,&interrupted);
          code=I386FrontendCommand(heap,cc,symbols,&raw_type);
          I386CommandInputCheckpoint(task,&interrupted);
          input->commands++;
          if(code) {
            if(!(input->flags&CCF_JUST_LOAD)) {
              value=state->declarations.execute(state,code);
              I386CommandInputCheckpoint(task,&interrupted);
              for(output=state->codes;output && output->code!=code;output=output->next);
              if(!output || !output->value_class) throw('Compiler',TRUE);
              if(raw_type!=RT_U0) {
                input->answers++;
                if(input->answer) input->answer(input->context,value,output->value_class);
              }
            }
            if(!(cc->flags&CCF_HAS_MISC_DATA)) I386FrontendFree(state,code);
          }
        }
        //Saved command views are gone; collect retired optimizer nodes as well.
        I386CommandInputCheckpoint(task,&interrupted);
        if(I386COCDiscard(heap,cc)) accepted=I386FrontendPublish(heap,cc,symbols);
      }
    }
  } catch {
    raised=TRUE; input->exception=task->except_ch; task->catch_except=TRUE;
  }
  if(cc) { input->errors=cc->error_cnt; input->warnings=cc->warning_cnt; }
  unwound=I386CmpCtrlUnwind(task,boundary);
  if(!unwound) accepted=FALSE;
  if(interrupted) {
    if(unwound) {
      irq=I386IrqSave;
      task->task_flags&=~(1<<TASKf_PENDING_BREAK);
      I386IrqRestore(irq);
    } else raised=FALSE; //Keep the request pending; do not jump past failed cleanup.
  }
  if(raised && input->exception!='Compiler' && input->exception!='OutMem')
    throw(input->exception,TRUE);
  return accepted;
}
