//One decoder consumes the hardware stream; focus receives public key messages.
#include "/Kernel/MessageCodes.HH"
#include "/Kernel/I386/KeyboardIdle.HC"
class CNativeKeyboardHooks {
  CTask *(*spawn)(U0 (*entry)(U8 *data),U8 *data,U8 *name,I64 cpu,
    CTask *parent,I64 stack_size,I64 flags);
  U0 (*post)(CTask *task,I64 code,I64 a,I64 b,I64 flags,I64 arrival);
  I64 (*scan)(I64 *a,I64 *b,I64 mask,CTask *task,I64 *arrival);
  U0 (*free)(U8 *address);
};
CNativeKeyboardHooks native_keyboard_hooks;
CTask *native_keyboard_owner,*native_keyboard_task;
I64 native_keyboard_losses,native_keyboard_seen;
U0 NativeKeyboardDiscard(CTask *task)
{//Reset incomplete console input without discarding unrelated command jobs.
  CJob *head,*job,*next;
  U32 irq=I386IrqSave;
  if(TaskValidate(task)) {
    while(task->srv_ctrl.flags&(1<<JOBCf_LOCKED)) {}
    task->srv_ctrl.flags|=1<<JOBCf_LOCKED;
    head=&task->srv_ctrl.next_waiting;
    job=head->next;
    while(job!=head) {
      next=job->next;
      if(job->job_code==JOBT_MSG &&
          (job->msg_code==MSG_KEY_DOWN || job->msg_code==MSG_KEY_UP)) {
        job->last->next=job->next; job->next->last=job->last;
        (*native_keyboard_hooks.free)(job->aux_str);
        (*native_keyboard_hooks.free)(job);
      }
      job=next;
    }
    task->srv_ctrl.flags&=~(1<<JOBCf_LOCKED);
  }
  I386IrqRestore(irq);
}
Bool native_keyboard_reported;
Bool NativeKeyboardPump()
{//One shared decoder for the scheduled worker and masked debugger polling.
  CI386KeyEvent event;
  CTask *target;
  I64 decoded=0;
  U32 irq=I386IrqSave;
  //The configured reader and its input live for the console's lifetime.
  //An empty stream without an unreported loss cannot produce an event or
  //throw, so avoid creating an exception frame for the idle polling path.
  if(console_config && I386KeyboardIdle(console_config->reader)) {
    I386IrqRestore(irq);return FALSE;
  }
  try {
    decoded=I386KeyboardRead(console_config->reader,&event,FALSE);
    if(decoded<0) {
      native_keyboard_losses++;
      NativeTerminalDiscardKeyboard;
    } else if(decoded && !NativeTerminalFocusKey(&event)) {
      if(console_config->mouse && console_config->mouse->installed) {
        if(console_config->mouse->buttons&1)event.scan|=SCF_MS_L_DOWN;
        if(console_config->mouse->buttons&2)event.scan|=SCF_MS_R_DOWN;
      }
      target=sys_focus_task;
      if(!TaskValidate(target)) target=native_keyboard_owner;
      if(!native_keyboard_reported) {
        native_keyboard_reported=TRUE;
        KernelLog("KEYBOARD MESSAGE first "); KernelHex(event.type); KernelLog(" ");
        KernelHex(event.ch); KernelLog(" "); KernelHex(target); KernelLog(" ");
        KernelHex(target->task_signature); KernelLog("\n");
      }
      try {
        (*native_keyboard_hooks.post)(target,event.type,event.ch,event.scan,0,event.arrival_jiffy);
      } catch {
        I386TaskSelf->catch_except=TRUE;
        native_keyboard_losses++;
        NativeTerminalDiscardKeyboard;
      }
    }
  } catch { I386IrqRestore(irq); }
  I386IrqRestore(irq);return decoded!=0;
}
U0 NativeKeyboardWorker(U8 *data)
{
  KernelLog("KEYBOARD MESSAGE worker\n");
  SetRFlags(GetRFlags|512);
  while(TRUE) {
    NativeKeyboardPump;
    I386SchedYield(I386TaskSelf->owner);
  }
}
Bool NativeKeyboardStart()
{
  CHashExport *symbol;
  CTask *task=I386TaskSelf;
  if(native_keyboard_task) return FALSE;
  //The boot console is a private scheduler task until its first managed yield.
  //Enroll its public job queues before NativeReadKey can scan them.
  if(!I386SchedYield(I386TaskSelf->owner)) return FALSE;
  symbol=HashFind("_SPAWN",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!symbol) return FALSE;
  native_keyboard_hooks.spawn=symbol->val;
  symbol=HashFind("I386PostKeyTimed",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!symbol) return FALSE;
  native_keyboard_hooks.post=symbol->val;
  symbol=HashFind("I386ScanKeyTimed",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!symbol) return FALSE;
  native_keyboard_hooks.scan=symbol->val;
  symbol=HashFind("_FREE",task->hash_table,HTT_EXPORT_SYS_SYM);
  if(!symbol) return FALSE;
  native_keyboard_hooks.free=symbol->val;
  native_keyboard_owner=task;
  native_keyboard_task=(*native_keyboard_hooks.spawn)(&NativeKeyboardWorker,0,
    "Keyboard",-1,0,8192,256);
  KernelLog("KEYBOARD MESSAGE start "); KernelHex(task); KernelLog(" ");
  KernelHex(native_keyboard_task); KernelLog("\n");
  return native_keyboard_task!=0;
}
I64 NativeReadKey(CI386KeyboardReader *reader,CI386KeyEvent *event,Bool wait=TRUE)
{//All console/document clients consume the public task queue, not the decoder.
  I64 code,*seen=NativeTerminalLossSeen;
  if(!native_keyboard_task || reader!=console_config->reader || !event) return -1;
  while(TRUE) {
    if(native_keyboard_losses!=*seen) {
      *seen=native_keyboard_losses;
      return -1;
    }
    code=(*native_keyboard_hooks.scan)(&event->ch,&event->scan,
      1<<MSG_KEY_DOWN|1<<MSG_KEY_UP,I386TaskSelf,&event->arrival_jiffy);
    if(code) { event->type=code; return 1; }
    if(!wait) return 0;
    I386SchedYield(I386TaskSelf->owner);
    I386TaskBreakPoll;
  }
}
