#include "/Kernel/I386/TaskHeaps.HH"
#include "/Kernel/I386/Frame.HH"
#include "/Kernel/SemaTypes.HH"
CI386Task *console_debug_task;
Bool console_debug_go;
U8 *console_debug_backup;
U0 (*console_debug_cleanup)(CI386Task *task);
U0 ConsoleDebugTaskCleanup(CI386Task *task)
{//Forced task exit bypasses the debugger's stack-local return path.
  U8 *backup=console_debug_backup;
  if(console_debug_task!=task) return;
  task->cleanup=console_debug_cleanup;
  console_debug_task=NULL; console_debug_go=FALSE;
  console_debug_backup=NULL; console_debug_cleanup=NULL;
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
  if(console_debug_task!=I386TaskSelf) throw('DbgState');
  if(ip!=U32_MAX || task && task!=I386TaskSelf) throw('DbgArg');
  console_debug_go=TRUE;
}
U0 ConsoleDebugSession(U8 *msg,I64 msg_num,CHashFun *fun,I64 exception=0)
{
  CI386Task *task=I386TaskSelf;
  CI386Text saved;
  CTask *focus=sys_focus_task;
  CI386KeyEvent event;
  U8 *backup,*p=&saved,*q=&console_text,line[256];
  I64 i,length=0,decoded,ch,failure=0;
  Bool raised=FALSE;
  if(console_debug_task) throw('DbgBusy');
  //Register cleanup before acquiring the display buffer.
  backup=NULL;
  try {
    backup=I386HeapAlloc(console_config->heap,153600,FALSE);
    if(!backup) throw('OutMem');
    for(i=0;i<153600;i++) backup[i]=console_planes[i];
    for(i=0;i<sizeof(CI386Text);i++) p[i]=q[i];
    console_debug_backup=backup; console_debug_cleanup=task->cleanup;
    task->cleanup=&ConsoleDebugTaskCleanup;
    console_debug_task=task; console_debug_go=FALSE; sys_focus_task=task;
    I386TextInit(&console_text,console_planes,sys_font_std);
    I386TextWrite(&console_text,"TempleOS i386\nHolyC debugger\n\n");
    if(exception) {
      I386TextWrite(&console_text,"Exception: ");
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
    if(exception) {
      I386TextWrite(&console_text,"\nSource: ");
      if(fun && fun->src_link) I386TextWrite(&console_text,fun->src_link);
      else I386TextWrite(&console_text,"unknown");
    }
    I386TextWrite(&console_text,"\ndbg> "); ConsolePresent;
    while(!console_debug_go) {
      decoded=NativeReadKey(console_config->reader,&event,TRUE);
      if(decoded<0) {length=0;I386TextWrite(&console_text,"\nInput reset\ndbg> ");}
      else if(decoded && event.type==2) {
        ch=event.ch;
        if(ch==3) {length=0;I386TextWrite(&console_text,"^C\ndbg> ");}
        else if(ch==8) {if(length){length--;I386TextPut(&console_text,8);}}
        else if(ch==10) {
          line[length]=0; I386TextPut(&console_text,10);
          ConsoleSource(line,"Debugger.HC"); length=0;
          if(!console_debug_go) I386TextWrite(&console_text,"dbg> ");
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
  if(console_debug_task==task) {
    task->cleanup=console_debug_cleanup;
    console_debug_backup=NULL; console_debug_cleanup=NULL;
    console_debug_task=NULL; console_debug_go=FALSE;
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
  if(console_debug_task || !NativeIsDebugMode || exception=='Break' ||
      exception=='Compiler' || exception=='OutMem') return;
  for(i=0;i<TASK_EXCEPT_CALLERS && !fun;i++)
    fun=ConsoleDebugFunction(task->except_callers[i]);
  ConsoleDebugSession(NULL,0,fun,exception);
}
