//Active controls are owned by this catch/unwind boundary. Persistent child
//references survive caught exceptions; borrowed contexts must return first.
Bool I386CommandInputBreakReady(CI386Task *task)
{
  U32 irq=I386IrqSave;
  Bool ready=(task->task_flags&(1<<TASKf_PENDING_BREAK)) &&
    !(task->task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_BREAK_TO_SHIFT_ESC)) &&
    !task->wait && !task->blocked && !task->io_locks && !task->compiler_busy &&
    !task->compiler_cleanup_failed && !task->messages &&
    task->lifetime_refs==task->active_controls+task->inherited_refs;
  I386IrqRestore(irq); return ready;
}
U0 I386ExecutionBreakPoll()
{//Entered by generated branches, never from IRQ context. The nearest HolyC
//handler may catch the break; an uncaught break reaches compiler input cleanup.
  U32 irq=I386IrqSave;
  CI386Task *task=I386TaskSelf;
  Bool ready=I386CommandInputBreakReady(task);
  if(ready) task->task_flags&=~(1<<TASKf_PENDING_BREAK);
  I386IrqRestore(irq);
  if(ready) throw('Break',TRUE);
}
U0 I386CommandInputCheckpoint(CI386Task *task,Bool *interrupted)
{
  Bool ready=I386CommandInputBreakReady(task);
  if(ready) *interrupted=TRUE;
  if(ready) throw('Break',TRUE);
}
Bool I386CommandInputHasDeclarations(CI386Frontend *state)
{
  I64 i;
  for(i=0;i<=state->table->mask;i++)
    if(state->table->body[i])return TRUE;
  return FALSE;
}
//Commit completed statements before parsing or executing a later failing one.
//The publisher validates and retains the complete ownership graph atomically.
Bool I386CommandInput(CI386CommandInput *input)
{
  CI386Task *task=I386TaskSelf;
  CI386Heap *heap;
  CI386TaskSymbols *answer_scope;
  CCmpCtrl *boundary,*cc=0;
  CI386Frontend *state=0;
  CPrsSymbolServices *symbols;
  CI386FrontendCode *output;
  U8 *code=0;
  U8 *context_source,*context_dest;
  I64 raw_type,value,i,saved_rbp,pointer_stars;
  U8 *saved_callers[TASK_EXCEPT_CALLERS];
  Bool accepted=FALSE,raised=FALSE,interrupted=FALSE,unwound;
  U32 irq;
  F64 started;
  if(!input) return FALSE;
  input->commands=0; input->answers=0; input->errors=0;
  input->warnings=0; input->exception=0;
  heap=input->heap;
  if(!task || !I386CmpTaskOwnerValid(task,heap,task->hash_table) || !input->source ||
      !input->filename && !input->inherit_context || !input->types || !input->files ||
      input->files->version!=I386_FILE_SERVICES_VERSION ||
      input->files->bytes!=sizeof(CI386FileServices) || !input->files->control_new ||
      input->flags&CCF_AOT_COMPILE ||
      input->document && *input->source) return FALSE;
  answer_scope=task->symbol_state;
  boundary=task->last_cc;
  try {
    I386CommandInputCheckpoint(task,&interrupted);
    cc=input->files->control_new(input->source,(input->flags&~I386_INPUT_ATOMIC_DEFINES)|CCF_DONT_FREE_BUF|CCF_AOT_COMPILE,input->filename);
    if(!cc) I386CommandInputCheckpoint(task,&interrupted);
    if(cc) {
      //Match original ExePutS before entering the new control or lexing.
      if(input->inherit_context && boundary!=&task->next_cc) {
        cc->opts=boundary->opts;
        if(input->hash_context) {
          cc->flags=cc->flags&~CCF_ASM_EXPRESSIONS |
            input->hash_context->old_flags&CCF_ASM_EXPRESSIONS;
          context_source=input->hash_context;context_dest=&cc->htc;
          for(i=0;i<sizeof(CLexHashTableContext);i++)
            context_dest[i]=context_source[i];
        }
      }
      if(input->document && !I386LexAttachDocRoot(heap,cc,input->document) ||
          !I386CmpCtrlEnter(heap,cc)) {
        I386CmpCtrlDel(heap,cc); cc=0;
      } else {
        symbols=I386FrontendServices(heap,cc,input->types,input->includes);
        if(!symbols) throw('OutMem',TRUE);
        state=symbols->context; state->files=input->files;
        state->command_publication=!(input->flags&I386_INPUT_ATOMIC_DEFINES);
        if(input->flags&I386_INPUT_ATOMIC_DEFINES &&
            !I386FrontendPrivateDefines(symbols)) throw('OutMem',TRUE);
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
              //Capture the category before nested execution can retire metadata.
              for(output=state->codes;output && output->code!=code;output=output->next);
              if(!output || !output->value_class) throw('Compiler',TRUE);
              pointer_stars=output->value_class->ptr_stars_cnt;
              if(input->execution_time)started=(*input->execution_time)(input->context);
              value=state->declarations.execute(state,code);
              if(input->execution_time) {
                task->answer=value;task->answer_type=raw_type;
                answer_scope->answer_ptr_stars=pointer_stars;
                task->answer_time=(*input->execution_time)(input->context)-started;
                task->new_answer=TRUE;
              }
              I386CommandInputCheckpoint(task,&interrupted);
              for(output=state->codes;output && output->code!=code;output=output->next);
              if(!output || !output->value_class) throw('Compiler',TRUE);
              if(raw_type!=RT_U0) {
                input->answers++;
                if(input->answer) input->answer(input->context,value,output->value_class);
              }
            }
            if(!(cc->flags&CCF_HAS_MISC_DATA)) I386FrontendFree(state,code);
            code=0; //The completed expression is freed or belongs to retained storage.
          }
          if(!(input->flags&I386_INPUT_ATOMIC_DEFINES) && !state->fixups &&
              I386CommandInputHasDeclarations(state)) {
            if(!I386COCDiscard(heap,cc))throw('Compiler',TRUE);
            //Unresolved declarations can still be completed later in this input.
            //A rejected transfer leaves the staged graph owned by this control.
            I386FrontendPublish(heap,cc,symbols);
          }
        }
        //Saved command views are gone; collect retired optimizer nodes as well.
        I386CommandInputCheckpoint(task,&interrupted);
        if(I386COCDiscard(heap,cc)) accepted=I386FrontendPublish(heap,cc,symbols);
      }
    }
  } catch {
    raised=TRUE; input->exception=task->except_ch; task->catch_except=TRUE;
    //Cancelled includes can report a parser/allocation failure before returning
    //to a checkpoint. File borrows must already be released before conversion.
    if((input->exception=='Compiler' || input->exception=='OutMem') &&
        I386CommandInputBreakReady(task)) {
      interrupted=TRUE; input->exception='Break';
    }
  }
  if(raised && input->inspect_exception && input->exception!='Compiler' &&
      input->exception!='OutMem' && input->exception!='Break') {
    saved_rbp=task->except_rbp;
    for(i=0;i<TASK_EXCEPT_CALLERS;i++) saved_callers[i]=task->except_callers[i];
    try { input->inspect_exception(input->context,task,cc,input->exception); }
    catch {
      task->catch_except=TRUE;
      if(input->diagnostic) input->diagnostic(input->context,cc,0,"Debugger inspection failed");
    }
    task->except_ch=input->exception; task->except_rbp=saved_rbp;
    for(i=0;i<TASK_EXCEPT_CALLERS;i++) task->except_callers[i]=saved_callers[i];
  }
  //A completed child graph also survives an uncaught break in its caller.
  //The same graph validator still rejects unfinished or invalid declarations.
  if(raised && !(input->flags&I386_INPUT_ATOMIC_DEFINES) &&
      state && state->published_children &&
      input->exception!='Compiler' && input->exception!='OutMem') {
    try {
      if(code && !(cc->flags&CCF_HAS_MISC_DATA)) {
        I386FrontendFree(state,code);code=0;
      }
      if(I386COCDiscard(heap,cc) && !I386FrontendPublish(heap,cc,&state->symbols))
        KernelLog("PARENT EXCEPTION publication rejected\n");
    } catch {
      task->catch_except=TRUE;
      KernelLog("PARENT EXCEPTION publication failed\n");
    }
  }
  if(cc) { input->errors=cc->error_cnt; input->warnings=cc->warning_cnt; }
  unwound=I386CmpCtrlUnwind(task,boundary);
  if(!unwound) accepted=FALSE;
  if(!unwound && input->exception=='Break') {
    irq=I386IrqSave; task->task_flags|=1<<TASKf_PENDING_BREAK; I386IrqRestore(irq);
    raised=FALSE;
  }
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
