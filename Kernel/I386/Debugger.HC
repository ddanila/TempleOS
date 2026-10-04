#include "/Kernel/I386/TaskHeaps.HH"
#include "/Kernel/I386/Frame.HH"
CI386Task *console_debug_task;
Bool console_debug_go;
U8 *ConsoleDebugFunction(U8 *address)
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
              if(size>0 && ip-base<size) return fun->str;
              owner=owner->parent;
            }
          }
        }
    table=table->next;
  }
  return "unknown";
}
U0 NativeDebugGo(U8 *ip=U32_MAX,CTask *task=NULL)
{
  if(console_debug_task!=I386TaskSelf) throw('DbgState');
  if(ip!=U32_MAX || task && task!=I386TaskSelf) throw('DbgArg');
  console_debug_go=TRUE;
}
U0 NativeDebug(U8 *msg=NULL,I64 msg_num=0)
{
  CI386Task *task=I386TaskSelf;
  CI386Frame *frame=GetRBP;
  CI386Text saved;
  CTask *focus=sys_focus_task;
  CI386KeyEvent event;
  U8 *backup,*name,*p=&saved,*q=&console_text,line[256];
  I64 i,length=0,decoded,ch,exception=0;
  Bool raised=FALSE;
  if(console_debug_task) throw('DbgBusy');
  name="unknown";
  if((frame+0)(U64)>=((&task->stk->stk_base)(U8 *)+0)(U64) &&
      (frame+0)(U64)<=((&task->stk->stk_base)(U8 *)+0)(U64)+task->stk->stk_size-8 &&
      !((frame+0)(U64)&3)) name=ConsoleDebugFunction(frame->return_address);
  //Register cleanup before acquiring the display buffer.
  backup=NULL;
  try {
    backup=I386HeapAlloc(console_config->heap,153600,FALSE);
    if(!backup) throw('OutMem');
    for(i=0;i<153600;i++) backup[i]=console_planes[i];
    for(i=0;i<sizeof(CI386Text);i++) p[i]=q[i];
    console_debug_task=task; console_debug_go=FALSE; sys_focus_task=task;
    I386TextInit(&console_text,console_planes,sys_font_std);
    I386TextWrite(&console_text,"TempleOS i386\nHolyC debugger\n\nMessage: ");
    if(msg) I386TextWrite(&console_text,msg);
    I386TextWrite(&console_text,"\nValue: "); ConsoleSigned(msg_num);
    I386TextWrite(&console_text,"\nFunction: "); I386TextWrite(&console_text,name);
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
    exception=task->except_ch; raised=TRUE; task->catch_except=TRUE;
  }
  if(backup) {
    for(i=0;i<153600;i++) console_planes[i]=backup[i];
    for(i=0;i<sizeof(CI386Text);i++) q[i]=p[i];
    console_text.dirty_first=0; console_text.dirty_last=60;
    I386HeapFree(console_config->heap,backup); ConsolePresent;
  }
  console_debug_task=NULL; console_debug_go=FALSE; sys_focus_task=focus;
  if(raised) throw(exception,TRUE);
}
