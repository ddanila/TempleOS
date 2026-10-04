class CNativeTextInput {
  CNativeTextInput *next;
  U8 *text;
  I64 offset;
};
class CNativeTerminal {
  CNativeTerminal *next,*previous;
  CI386Task *task;
  CI386Text surface;
  U8 *planes;
  CDoc *document;
  U0 (*cleanup)(CI386Task *task);
  I64 loss_seen;
  U8 *input_line;
  I64 input_capacity;
  CNativeTextInput *input_head,*input_tail;
  Bool owns_planes,running;
};
CNativeTerminal *native_terminal_head,*native_terminal_root;
Bool native_terminal_focus_held;
CNativeTerminal *NativeTerminalFind(CTask *task)
{
  CNativeTerminal *terminal=native_terminal_head;
  while(terminal && terminal->task!=task) terminal=terminal->next;
  return terminal;
}
CI386Text *NativeTerminalText()
{
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  if(!terminal) terminal=native_terminal_root;
  if(terminal) return &terminal->surface;
  return &console_default_text;
}
U8 **NativeTerminalPlanes()
{
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  if(!terminal) terminal=native_terminal_root;
  if(terminal) return &terminal->planes;
  return &console_default_planes;
}
Bool NativeTerminalVisible()
{
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  return !terminal || sys_focus_task==terminal->task;
}
I64 *NativeTerminalLossSeen()
{
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  if(terminal) return &terminal->loss_seen;
  return &native_keyboard_seen;
}
U0 NativeTerminalDiscardKeyboard()
{
  CNativeTerminal *terminal=native_terminal_head;
  native_terminal_focus_held=FALSE;
  while(terminal) {
    NativeKeyboardDiscard(terminal->task); terminal=terminal->next;
  }
  if(!NativeTerminalFind(sys_focus_task)) NativeKeyboardDiscard(sys_focus_task);
}
U0 NativeTerminalRelease(CI386Task *task)
{//Scheduler calls this while the finishing task and its public heaps are live.
  CNativeTerminal *terminal=NativeTerminalFind(task),*focus;
  U32 irq;
  CNativeTextInput *input;
  if(!terminal) return;
  if(terminal->cleanup) terminal->cleanup(task);
  if(terminal->document) {
    if(task->put_doc==terminal->document) task->put_doc=NULL;
    DocDel(terminal->document);
  }
  while(input=terminal->input_head) {
    terminal->input_head=input->next; Free(input->text); Free(input);
  }
  Free(terminal->input_line);
  irq=I386IrqSave;
  focus=terminal->next;
  if(!focus) focus=terminal->previous;
  if(terminal->previous) terminal->previous->next=terminal->next;
  else native_terminal_head=terminal->next;
  if(terminal->next) terminal->next->previous=terminal->previous;
  if(native_terminal_root==terminal) native_terminal_root=NULL;
  if(sys_focus_task==task) {
    sys_focus_task=NULL;
    if(focus) sys_focus_task=focus->task;
  } else focus=NULL;
  I386IrqRestore(irq);
  if(terminal->owns_planes) I386HeapFree(console_config->heap,terminal->planes);
  I386HeapFree(console_config->heap,terminal);
  task->cleanup=NULL;
  if(focus) {
    focus->surface.dirty_first=0; focus->surface.dirty_last=60;
    ConsolePresentText(&focus->surface);
  }
}
CNativeTerminal *NativeTerminalCreate(Bool root=FALSE)
{
  CI386Task *task=I386TaskSelf;
  CNativeTerminal *terminal=NULL,*last;
  I64 i;
  U8 *p,*q;
  U32 irq;
  if(NativeTerminalFind(task)) throw('TermBusy');
  try {
    terminal=I386HeapAlloc(console_config->heap,sizeof(CNativeTerminal),TRUE);
    if(!terminal) throw('OutMem');
    terminal->task=task; terminal->cleanup=task->cleanup;
    terminal->loss_seen=native_keyboard_losses;
    if(root) {
      terminal->planes=console_default_planes;
      p=&terminal->surface; q=&console_default_text;
      for(i=0;i<sizeof(CI386Text);i++) p[i]=q[i];
    } else {
      terminal->planes=I386HeapAlloc(console_config->heap,153600,FALSE);
      if(!terminal->planes) throw('OutMem');
      terminal->owns_planes=TRUE;
      if(!I386TextInit(&terminal->surface,terminal->planes,sys_font_std)) throw('TermVga');
      terminal->document=DocNew(NULL,task);
      if(!terminal->document) throw('OutMem');
    }
  } catch {
    if(terminal) {
      if(terminal->document) DocDel(terminal->document);
      if(terminal->owns_planes) I386HeapFree(console_config->heap,terminal->planes);
      I386HeapFree(console_config->heap,terminal);
    }
  }
  irq=I386IrqSave;
  last=native_terminal_head;
  if(last) {
    while(last->next) last=last->next;
    last->next=terminal; terminal->previous=last;
  } else native_terminal_head=terminal;
  task->cleanup=&NativeTerminalRelease;
  if(root) native_terminal_root=terminal;
  else task->put_doc=terminal->document;
  I386IrqRestore(irq);
  return terminal;
}
U0 NativeTerminalAdoptRoot() { NativeTerminalCreate(TRUE); }
CTask *NativeWinFocus(CTask *task=NULL)
{
  CNativeTerminal *terminal;
  U32 irq=I386IrqSave;
  if(!task) task=I386TaskSelf;
  if(!TaskValidate(task) || task->win_inhibit&1) {
    task=NULL;
    if(native_terminal_root) task=native_terminal_root->task;
  }
  sys_focus_task=task;
  terminal=NativeTerminalFind(task);
  I386IrqRestore(irq);
  if(terminal) {
    terminal->surface.dirty_first=0; terminal->surface.dirty_last=60;
    ConsolePresentText(&terminal->surface);
  }
  return task;
}
Bool NativeTerminalFocusKey(CI386KeyEvent *event)
{//Run in the keyboard worker, never IRQ context. Consume the hotkey's pair.
  CNativeTerminal *terminal,*start;
  Bool held;
  if(((event->scan>>32)&255)!=0x31) return FALSE;
  if(event->type==MSG_KEY_UP) {
    held=native_terminal_focus_held;
    native_terminal_focus_held=FALSE;
    return held;
  }
  if(event->type!=MSG_KEY_DOWN) return FALSE;
  if(native_terminal_focus_held) return TRUE;
  if((event->scan&0xC00)!=0xC00) return FALSE;
  native_terminal_focus_held=TRUE;
  terminal=NativeTerminalFind(sys_focus_task);
  if(terminal) terminal=terminal->next;
  if(!terminal) terminal=native_terminal_head;
  start=terminal;
  if(!terminal) return TRUE;
  do {
    if(TaskValidate(terminal->task) && !terminal->task->finishing &&
        !(terminal->task->win_inhibit&1)) {
      NativeWinFocus(terminal->task); return TRUE;
    }
    terminal=terminal->next;
    if(!terminal) terminal=native_terminal_head;
  } while(terminal!=start);
  return TRUE;
}
U0 NativeUserTaskCont()
{
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  Bool retry;
  if(!terminal) terminal=NativeTerminalCreate;
  if(terminal->running) throw('TermBusy');
  terminal->running=TRUE;
  do {
    retry=FALSE;
    try { NativeTerminalInput; }
    catch {
      //Like UserTaskCont, keep the user's task and definitions after a break.
      I386TaskSelf->catch_except=TRUE;
      I386TextWrite(&console_text,"Exception\n");
      ConsolePresent;
      retry=TRUE;
    }
  } while(retry);
  terminal->running=FALSE;
}
U0 NativeTerminalConsoleHeading()
{
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  if(terminal && terminal!=native_terminal_root) {
    I386TextWrite(&terminal->surface,"TempleOS i386\nHolyC console\nTask: ");
    I386TextWrite(&terminal->surface,terminal->task->task_title);
    I386TextWrite(&terminal->surface,"\n\n");
  } else I386TextWrite(&console_text,console_title);
}
U0 NativeUserCmdLine(I64 dummy=0)
{
  CNativeTerminal *terminal;
  SetRFlags(GetRFlags|512);
  terminal=NativeTerminalFind(I386TaskSelf);
  if(!terminal) {
    terminal=NativeTerminalCreate;
    NativeTerminalConsoleHeading;
  }
  KernelLog("USER headers begin\n");
  if(!ConsoleSource("#include \"/Kernel/I386/PublicUser.HH\"\n",
      "UserHeaders.HC",I386_INPUT_ATOMIC_DEFINES|CCF_JUST_LOAD))
    throw('UserHdr',TRUE);
  KernelLog("USER headers ok\n");
  if(!HashFind("ST_COLORS",Fs->hash_table,HTT_DEFINE_STR))
    DefineLstLoad("ST_COLORS",COLOR_NAMES_LIST);
  KernelLog("USER input begin\n");
  NativeUserTaskCont;
}

U8 *NativeTerminalLine(I64 required)
{//Keep input storage in the terminal so break and forced exit cannot leak it.
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  U8 *line;
  I64 capacity;
  if(!terminal || required<1 || required>I32_MAX/2) throw('TermInpt');
  if(required>terminal->input_capacity) {
    capacity=terminal->input_capacity;
    if(capacity<256) capacity=256;
    while(capacity<required) capacity*=2;
    line=MAlloc(capacity,terminal->task);
    if(terminal->input_line) {
      MemCpy(line,terminal->input_line,terminal->input_capacity);
      Free(terminal->input_line);
    }
    terminal->input_line=line; terminal->input_capacity=capacity;
  }
  return terminal->input_line;
}
I64 NativeTerminalInputKey(CI386KeyEvent *event)
{
  CNativeTerminal *terminal=NativeTerminalFind(I386TaskSelf);
  CNativeTextInput *input;
  I64 ch;
  U32 flags;
  if(!terminal) throw('TermInpt');
  flags=I386IrqSave;
  input=terminal->input_head;
  if(input) {
    ch=input->text[input->offset++];
    if(!input->text[input->offset]) {
      terminal->input_head=input->next;
      if(!terminal->input_head) terminal->input_tail=NULL;
    } else input=NULL;
    event->type=MSG_KEY_DOWN; event->ch=ch; event->scan=0;
    I386IrqRestore(flags);
    if(input) { Free(input->text); Free(input); }
    return 1;
  }
  I386IrqRestore(flags);
  return NativeReadKey(console_config->reader,event,FALSE);
}
U0 NativeTaskWait(CTask *task=NULL,Bool cmd_line_pmt=FALSE)
{
  CTask *target;
  if(!task) task=Fs;
  while(TaskValidate(task)) {
    target=task->last_input_filter_task;
    if(!TaskValidate(target) || target==Fs) return;
    if(Bt(&target->task_flags,TASKf_IDLE) &&
        (!cmd_line_pmt || Bt(&target->task_flags,TASKf_CMD_LINE_PMT))) return;
    I386SchedYield(I386TaskSelf->owner); I386TaskBreakPoll;
  }
}
U0 NativeXTalk(CTask *task,U8 *fmt,...)
{//Format in the sender; the queued copy belongs to the destination task.
  CNativeTerminal *terminal;
  CNativeTextInput *input=NULL;
  U8 *text=NULL;
  I64 exception=0;
  Bool failed=FALSE;
  U32 irq;
  NativeTaskWait(task);
  terminal=NativeTerminalFind(task);
  if(!terminal || !TaskValidate(task) || task(CI386Task *)->finishing)
    throw('TaskDead');
  try {
    text=StrPrintJoin(NULL,fmt,argc,argv);
    if(*text) {
      input=CAlloc(sizeof(CNativeTextInput),task);
      input->text=StrNew(text,task);
    }
  } catch {
    failed=TRUE; exception=Fs->except_ch; Fs->catch_except=TRUE;
  }
  Free(text);
  if(failed) {
    if(input) { Free(input->text); Free(input); }
    throw(exception,TRUE);
  }
  if(!input) return;
  irq=I386IrqSave;
  if(terminal->input_tail) terminal->input_tail->next=input;
  else terminal->input_head=input;
  terminal->input_tail=input;
  task->task_flags&=~(1<<TASKf_IDLE|1<<TASKf_CMD_LINE_PMT);
  I386SchedWake(task(CI386Task *)->owner,task);
  I386IrqRestore(irq);
}
CTask *NativeUser(U8 *fmt=NULL,...)
{
  CTask *task;
  U8 *text=NULL;
  I64 exception=0;
  Bool failed=FALSE;
  task=(*native_user_providers.spawn)(&NativeUserCmdLine,NULL,NULL,-1,NULL,0,256);
  if(!task) return NULL;
  try {
    NativeTaskWait(task);
    if(fmt) {
      text=StrPrintJoin(NULL,fmt,argc,argv);
      NativeXTalk(task,text);
    }
  } catch {
    failed=TRUE; exception=Fs->except_ch; Fs->catch_except=TRUE;
  }
  Free(text);
  if(failed) {
    (*native_user_providers.kill)(task,TRUE,FALSE);
    throw(exception,TRUE);
  }
  return task;
}
