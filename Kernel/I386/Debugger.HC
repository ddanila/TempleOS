#include "/Kernel/I386/Frame.HH"
U8 *NativeCaller(I64 num=1)
{//Same public depth convention, with owned original/debug stack bounds.
  CI386Task *task=I386TaskSelf;
  CI386Frame *frame=GetRBP;
  if(!task || !task->stk || num<0 || num>task->stk->stk_size/sizeof(CI386Frame)) return 0;
  while(num--) {
    frame=I386TaskFrameParent(task,frame);
    if(!frame) return 0;
  }
  return I386TaskFrameReturn(task,frame);
}
#include "/Kernel/I386/PublicDebugTypes.HH"
extern U0 NativeBptOwnTask(CTask *task);
CBpt *BptFind(U8 *needle_addr,CTask *haystack_task=NULL,Bool rem=FALSE)
{
  CBpt *res=NULL,*tmpb,*tmpb1,*tmpb2;
  if (!haystack_task) haystack_task=I386TaskSelf;
  U32 irq=I386IrqSave;
  tmpb1=&haystack_task->bpt_lst;
  tmpb=haystack_task->bpt_lst;
  while (tmpb) {
    tmpb2=tmpb->next;
    if (tmpb->addr==needle_addr) {
      res=tmpb;
      if (rem)
	tmpb1->next=tmpb2;
      else
	tmpb1=&tmpb->next;
    } else
      tmpb1=&tmpb->next;
    tmpb=tmpb2;
  }
  I386IrqRestore(irq);
  return res;
}

Bool BptS(U8 *addr,CTask *task=NULL,Bool live=TRUE)
{//Set breakpoint.
  CBpt *tmpb;
  Bool res=TRUE;
  if (!task) task=I386TaskSelf;
  U32 irq=I386IrqSave;
  if (!(tmpb=BptFind(addr,task,FALSE))) {
    tmpb=CAlloc(sizeof(CBpt),task);
    tmpb->addr=addr;
    tmpb->val=*addr;
    res=FALSE;
    tmpb->next=task->bpt_lst;
    task->bpt_lst=tmpb;
    NativeBptOwnTask(task);
    if (task==I386TaskSelf && live)
      *addr=0xCC;
  }
  I386IrqRestore(irq);
  return res;
}

Bool BptR(U8 *addr,CTask *task=NULL,Bool live=TRUE,Bool rem=TRUE)
{//Rem breakpoint.
  CBpt *tmpb;
  Bool res=FALSE;
  if (!task) task=I386TaskSelf;
  U32 irq=I386IrqSave;
  if (tmpb=BptFind(addr,task,rem)) {
    if (task==I386TaskSelf && live)
      *tmpb->addr=tmpb->val;
    res=TRUE;
    if (rem)
      Free(tmpb);
  }
  I386IrqRestore(irq);
  return res;
}

Bool B(U8 *addr,CTask *task=NULL,Bool live=TRUE)
{//Toggle breakpoint.
//Return: TRUE if removed.
  Bool res=FALSE;
  U32 irq=I386IrqSave;
  if (BptFind(addr,task,FALSE)) {
    BptR(addr,task,live,TRUE);
    res=TRUE;
  } else
    BptS(addr,task,live);
  I386IrqRestore(irq);
  return res;
}

I64 B2(CTask *task=NULL,Bool live=TRUE)
{//Rem all breakpoints.
//Return: cnt of removed.
  I64 res=0;
  CBpt *tmpb,*tmpb1;
  if (!task) task=I386TaskSelf;
  U32 irq=I386IrqSave;
  tmpb=task->bpt_lst;
  task->bpt_lst=NULL;
  while (tmpb) {
    tmpb1=tmpb->next;
    if (task==I386TaskSelf && live)
      *tmpb->addr=tmpb->val;
    Free(tmpb);
    tmpb=tmpb1;
    res++;
  }
  I386IrqRestore(irq);
  return res;
}

I64 *TaskRegAddr(CTask *task,I64 reg_num)
{
  switch (reg_num) {
    case REG_RAX: return &task->rax;
    case REG_RCX: return &task->rcx;
    case REG_RDX: return &task->rdx;
    case REG_RBX: return &task->rbx;
    case REG_RSP: return &task->rsp;
    case REG_RBP: return &task->rbp;
    case REG_RSI: return &task->rsi;
    case REG_RDI: return &task->rdi;
    case 8 : return &task->r8;
    case 9 : return &task->r9;
    case 10: return &task->r10;
    case 11: return &task->r11;
    case 12: return &task->r12;
    case 13: return &task->r13;
    case 14: return &task->r14;
    case 15: return &task->r15;
  }
  return NULL;
}

#include "/Kernel/I386/TaskHeaps.HH"
#include "/Kernel/I386/Frame.HH"
#include "/Kernel/SemaTypes.HH"
U32 console_debug_sessions;
Bool console_debug_previous_mode;
U0 NativeDebugSessionEnter()
{
  U32 irq=I386IrqSave;
  if(!console_debug_sessions) console_debug_previous_mode=NativeDebugMode(TRUE);
  console_debug_sessions++;
  I386IrqRestore(irq);
}
U0 NativeDebugSessionLeave()
{
  U32 irq=I386IrqSave;
  if(!console_debug_sessions) KernelStop;
  console_debug_sessions--;
  if(!console_debug_sessions) NativeDebugMode(console_debug_previous_mode);
  I386IrqRestore(irq);
}
U0 (*native_bpt_platform_bind)(CI386Task *task);
U0 NativeBptApply(CTask *task,Bool active)
{//IRQ-masked, no allocation or scheduling.
  CBpt *record=task->bpt_lst;
  while(record) {
    if(active) *record->addr=0xCC;
    else *record->addr=record->val;
    record=record->next;
  }
}
U0 NativeBptTaskCleanup(CI386Task *task)
{//Restore code before public heaps or executable allocations disappear.
  CBpt *record,*next;
  U0 (*previous)(CI386Task *task);
  previous=task->debug_bpt_cleanup;
  NativeBptApply(task,FALSE);
  record=task->bpt_lst;task->bpt_lst=NULL;
  while(record) { next=record->next;Free(record);record=next; }
  task->debug_bpt_cleanup=NULL;task->cleanup=previous;
  if(previous) (*previous)(task);
}
U0 NativeBptOwnTask(CTask *task)
{
  CI386Task *native=task;
  if(native->debug_session_active) {
    if(native->debug_cleanup==&NativeBptTaskCleanup) return;
    native->debug_bpt_cleanup=native->debug_cleanup;
    native->debug_cleanup=&NativeBptTaskCleanup;
  } else {
    if(native->cleanup==&NativeBptTaskCleanup) return;
    native->debug_bpt_cleanup=native->cleanup;
    native->cleanup=&NativeBptTaskCleanup;
  }
}
U0 NativeBreakpointBind(CI386Task *next)
{//FS still names outgoing task; chain the original segment binder last.
  NativeBptApply(I386TaskSelf,FALSE);
  NativeBptApply(next,!Bt(&next->task_flags,TASKf_DISABLE_BPTS));
  (*native_bpt_platform_bind)(next);
}
U0 NativeBreakpointInstall()
{
  U32 irq=I386IrqSave;
  if(native_bpt_platform_bind || !I386TaskSelf->owner->bind) KernelStop;
  native_bpt_platform_bind=I386TaskSelf->owner->bind;
  I386TaskSelf->owner->bind=&NativeBreakpointBind;
  I386IrqRestore(irq);
}
U0 ConsoleDebugTaskCleanup(CI386Task *task)
{//Forced task exit bypasses the debugger's stack-local return path.
  U8 *backup=task->debug_backup;
  if(!task->debug_session_active) return;
  NativeDebugSessionLeave();
  task->cleanup=task->debug_cleanup;
  task->debug_session_active=FALSE; task->debug_go=FALSE;
  task->debug_backup=NULL; task->debug_cleanup=NULL;
  if(backup) I386HeapFree(console_config->heap,backup);
  if(task->cleanup) (*task->cleanup)(task);
}
CHashFun *ConsoleDebugFunction(U8 *address)
{//Only name a function whose executable allocation contains the return IP.
  CHashTable *table=I386TaskSelf->hash_table;
  CHash *entry;
  CHashFun *fun;
  CI386TaskHeaps *owner;
  I64 bucket,size;
  U64 ip=(address+0)(U64),base;
  while(table) {
    for(bucket=0;bucket<=table->mask;bucket++)
      for(entry=table->body[bucket];entry;entry=entry->next)
        if(entry->type&HTT_FUN) {
          fun=entry; base=(fun->exe_addr+0)(U64);
          if(base && ip>=base) {
            owner=I386TaskSelf->heap_state;
            while(owner) {
              size=0;
              if(owner->code_capacity) size=owner->code_capacity(owner,fun->exe_addr);
              if(size>0 && ip-base<size) return fun;
              owner=owner->parent;
            }
          }
        }
    table=table->next;
  }
  return NULL;
}
U0 NativeDebugGo(U8 *ip=U32_MAX,CTask *task=NULL)
{
  if(!I386TaskSelf->debug_session_active) throw('DbgState');
  if(task && task!=I386TaskSelf) throw('DbgArg');
  if(ip!=U32_MAX) {
    if(!I386TaskSelf->debug_cpu_active) throw('DbgState');
    I386TaskSelf->debug_cpu_frame.eip=(ip+0)(U64);
    I386TaskSelf->rip=(ip+0)(U64);
  }
  //Public RIP edits and explicit G(ip) select the same physical return IP.
  if(I386TaskSelf->debug_cpu_active) I386TaskSelf->debug_cpu_frame.eip=(I386TaskSelf->rip+0)(U64);
  if(I386TaskSelf->debug_cpu_active) {
    if(BptFind(I386TaskSelf->debug_cpu_frame.eip(U8 *))) {
      I386TextWrite(&console_text,"Use S, B2 or G2 before resuming a breakpoint.\n");
      return;
    }
    //Resume public flags; G owns TF exactly as in the original debugger.
    I386TaskSelf->rflags&=~0x100;
    I386TaskSelf->debug_cpu_frame.eflags=I386TaskSelf->rflags;
    LBtr(&I386TaskSelf->task_flags,TASKf_DISABLE_BPTS);
    NativeBptApply(I386TaskSelf,TRUE);
  }
  I386TaskSelf->debug_go=TRUE;
}
U0 NativeDebugGoClear(U8 *ip=U32_MAX,CTask *task=NULL)
{//Original G2: remove all managed records, then resume.
  if(!I386TaskSelf->debug_session_active) throw('DbgState');
  if(task && task!=I386TaskSelf) throw('DbgArg');
  B2(task);
  NativeDebugGo(ip,task);
}
U0 NativeDebugStep(U8 *ip=U32_MAX,CTask *task=NULL)
{
  if(!I386TaskSelf->debug_session_active || !I386TaskSelf->debug_cpu_active) throw('DbgState');
  if(task && task!=I386TaskSelf) throw('DbgArg');
  if(ip!=U32_MAX) {
    if(!I386TaskSelf->debug_cpu_active) throw('DbgState');
    I386TaskSelf->debug_cpu_frame.eip=(ip+0)(U64);
    I386TaskSelf->rip=(ip+0)(U64);
  }
  I386TaskSelf->debug_cpu_frame.eip=(I386TaskSelf->rip+0)(U64);
  LBts(&I386TaskSelf->task_flags,TASKf_DISABLE_BPTS);
  NativeBptApply(I386TaskSelf,FALSE);
  I386TaskSelf->rflags|=0x100;
  I386TaskSelf->debug_cpu_frame.eflags=I386TaskSelf->rflags;
  I386TaskSelf->debug_go=TRUE;
}
U0 ConsoleDebugSession(U8 *msg,I64 msg_num,CHashFun *fun,I64 exception=0,
  Bool is_exception=FALSE)
{
  CI386Task *task=I386TaskSelf;
  CI386Text saved;
  CTask *focus=sys_focus_task;
  CI386KeyEvent event;
  U8 *backup,*p=&saved,*q=&console_text,line[256];
  I64 i,length=0,decoded,ch,failure=0;
  Bool raised=FALSE;
  if(task->debug_session_active) throw('DbgBusy');
  //Register cleanup before acquiring the display buffer.
  backup=NULL;
  try {
    backup=I386HeapAlloc(console_config->heap,153600,FALSE);
    if(!backup) throw('OutMem');
    for(i=0;i<153600;i++) backup[i]=console_planes[i];
    for(i=0;i<sizeof(CI386Text);i++) p[i]=q[i];
    NativeDebugSessionEnter();
    task->debug_backup=backup; task->debug_cleanup=task->cleanup;
    task->cleanup=&ConsoleDebugTaskCleanup;
    task->debug_session_active=TRUE; task->debug_go=FALSE; sys_focus_task=task;
    I386TextInit(&console_text,console_planes,sys_font_std);
    I386TextWrite(&console_text,"TempleOS i386\nHolyC debugger\n\n");
    if(is_exception) {
      I386TextWrite(&console_text,"Exception: ");
      if(!exception) I386TextPut(&console_text,'0');
      for(i=0;i<8;i++) {
        ch=(exception>>(i*8))&255;
        if(!ch) break;
        I386TextPut(&console_text,ch);
      }
    } else {
      I386TextWrite(&console_text,"Message: ");
      if(msg) I386TextWrite(&console_text,msg);
      I386TextWrite(&console_text,"\nValue: "); ConsoleSigned(msg_num);
    }
    I386TextWrite(&console_text,"\nFunction: ");
    if(fun) I386TextWrite(&console_text,fun->str);
    else I386TextWrite(&console_text,"unknown");
    if(is_exception) {
      I386TextWrite(&console_text,"\nSource: ");
      if(fun && fun->src_link) I386TextWrite(&console_text,fun->src_link);
      else I386TextWrite(&console_text,"unknown");
    }
    I386TextWrite(&console_text,"\ndbg> "); ConsolePresent;
    while(!I386TaskSelf->debug_go) {
      decoded=NativeReadKey(console_config->reader,&event,TRUE);
      if(decoded<0) {length=0;I386TextWrite(&console_text,"\nInput reset\ndbg> ");}
      else if(decoded && event.type==2) {
        ch=event.ch;
        if(ch==3) {length=0;I386TextWrite(&console_text,"^C\ndbg> ");}
        else if(ch==8) {if(length){length--;I386TextPut(&console_text,8);}}
        else if(ch==10) {
          line[length]=0; I386TextPut(&console_text,10);
          ConsoleSource(line,"Debugger.HC"); length=0;
          if(!I386TaskSelf->debug_go) I386TextWrite(&console_text,"dbg> ");
        } else if(ch>=32 && ch<=255 && length<255) {
          line[length++]=ch; I386TextPut(&console_text,ch);
        }
      }
      ConsolePresent;
    }
  } catch {
    failure=task->except_ch; raised=TRUE; task->catch_except=TRUE;
  }
  if(backup) {
    for(i=0;i<153600;i++) console_planes[i]=backup[i];
    for(i=0;i<sizeof(CI386Text);i++) q[i]=p[i];
    NativeTerminalText()->dirty_first=0; NativeTerminalText()->dirty_last=60;
    I386HeapFree(console_config->heap,backup); ConsolePresent;
  }
  if(task->debug_session_active) {
    NativeDebugSessionLeave();
    task->cleanup=task->debug_cleanup;
    task->debug_backup=NULL; task->debug_cleanup=NULL;
    task->debug_session_active=FALSE; task->debug_go=FALSE;
  }
  sys_focus_task=focus;
  if(raised) throw(failure,TRUE);
}

CSema *ConsoleDebugSemas()
{
  CHashExport *entry=HashFind("_SYS_SEMAS",I386TaskSelf->hash_table,HTT_EXPORT_SYS_SYM);
  if(!entry) throw('DbgSvc');
  return entry->val;
}
Bool NativeDebugMode(Bool value)
{
  CSema *semas=ConsoleDebugSemas;
  U32 irq=I386IrqSave;
  Bool previous=semas[SEMA_DBG_MODE].val&1;
  if(value) semas[SEMA_DBG_MODE].val|=1;
  else semas[SEMA_DBG_MODE].val&=~1;
  I386IrqRestore(irq); return previous;
}
Bool NativeIsDebugMode()
{
  CSema *semas=ConsoleDebugSemas;
  return semas[SEMA_DBG_MODE].val&1;
}
U0 NativeDebug(U8 *msg=NULL,I64 msg_num=0)
{
  CI386Task *task=I386TaskSelf;
  CI386Frame *frame=GetRBP;
  CHashFun *fun=NULL;
  if((frame+0)(U64)>=((&task->stk->stk_base)(U8 *)+0)(U64) &&
      (frame+0)(U64)<=((&task->stk->stk_base)(U8 *)+0)(U64)+task->stk->stk_size-8 &&
      !((frame+0)(U64)&3)) fun=ConsoleDebugFunction(frame->return_address);
  ConsoleDebugSession(msg,msg_num,fun);
}
U0 ConsoleDebugException(U8 *context,CI386Task *task,CCmpCtrl *cc,I64 exception)
{
  CHashFun *fun=NULL;
  I64 i;
  if(task->debug_session_active || !NativeIsDebugMode || exception=='Break' ||
      exception=='Compiler' || exception=='OutMem') return;
  for(i=0;i<TASK_EXCEPT_CALLERS && !fun;i++)
    fun=ConsoleDebugFunction(task->except_callers[i]);
  ConsoleDebugSession(NULL,0,fun,exception,TRUE);
}

Bool ConsoleCpuCapture(CI386ExceptionFrame *frame)
{//Called with IF clear: no allocation, console IO or scheduling.
  CI386Task *task=I386TaskSelf;
  U8 *src=frame,*dst;
  I64 i;
  CBpt *managed=NULL;
  if(!task || task->debug_cpu_active || task->debug_session_active ||
      (frame->vector!=3 && frame->vector!=1) || frame->cs!=8 || !(frame->eflags&0x200)) return FALSE;
  dst=&task->debug_cpu_frame;
  for(i=0;i<sizeof(CI386ExceptionFrame);i++) dst[i]=src[i];
  if(frame->vector==3) managed=BptFind((frame->eip-1)(U8 *),task);
  if(managed) {
    dst=&task->debug_cpu_frame;
    task->debug_cpu_frame.eip--;
    LBts(&task->task_flags,TASKf_DISABLE_BPTS);
    NativeBptApply(task,FALSE);
  }
  //Public I64 debugger shadows; scheduling uses private CI386Context.
  task->rax=frame->eax;task->rcx=frame->ecx;task->rdx=frame->edx;
  task->rbx=frame->ebx;task->rbp=frame->ebp;task->rsi=frame->esi;task->rdi=frame->edi;
  task->rip=task->debug_cpu_frame.eip;task->rflags=frame->eflags;
  task->rsp=frame->saved_esp+20; //Past vector/error/eip/cs/eflags.
  task->debug_cpu_active=TRUE; return TRUE;
}
U0 ConsoleCpuDebug(CI386ExceptionFrame *frame)
{//Normal task context; reconstruct a complete exception-return frame.
  CI386Task *task=I386TaskSelf;
  U8 *src=&task->debug_cpu_frame,*dst=frame;
  I64 i;
  if(!task->debug_cpu_active || !(GetRFlags&0x200)) KernelStop;
  task->debug_cpu_frame.eflags&=~0x100;
  ConsoleDebugSession(NULL,0,
    ConsoleDebugFunction(task->debug_cpu_frame.eip(U8 *)),'BreakPt',TRUE);
  //G/S commit IP/flags; exception-entry assembly relocates to public RSP.
  task->debug_cpu_frame.eax=task->rax;task->debug_cpu_frame.ecx=task->rcx;
  task->debug_cpu_frame.edx=task->rdx;task->debug_cpu_frame.ebx=task->rbx;
  task->debug_cpu_frame.ebp=task->rbp;task->debug_cpu_frame.esi=task->rsi;
  task->debug_cpu_frame.edi=task->rdi;
  for(i=0;i<sizeof(CI386ExceptionFrame);i++) dst[i]=src[i];
  task->debug_cpu_active=FALSE;
}
