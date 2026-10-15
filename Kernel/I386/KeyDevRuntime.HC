#include "/Kernel/KeyDevTypes.HH"
#include "/Kernel/ScanFlags.HH"
CKeyDevGlbls keydev;
Bool native_keydev_ready;
U8 *ACAlloc(I64 size)
{
  return CAlloc(size,I386TaskSelf->owner->root);
}
#define KEYDEV_SCAN_CODE (console_config->reader->state.keys.locks)
#include "/Kernel/KeyDevOutputCore.HC"
I64 ScanMsg(I64 *a=NULL,I64 *b=NULL,I64 mask=~1,CTask *task=NULL)
{
  return (*native_public_scan_msg)(a,b,mask,task);
}
#include "/Kernel/KeyScanCore.HC"
extern Bool NativeKeyboardPump();
class CNativeKeyClock { I64 ticks,cycles;U16 count; };
U0 NativeKeyClockStart(CNativeKeyClock *clock)
{
  U32 irq=I386IrqSave;
  clock->ticks=*console_config->jiffies;clock->count=NativeRandPitRead;
  clock->cycles=clock->ticks*console_config->pit_divisor;
  I386IrqRestore(irq);
}
Bool NativeKeyClockPhase(CNativeKeyClock *clock)
{
  U32 irq=I386IrqSave;
  I64 ticks=*console_config->jiffies,count=NativeRandPitRead,
    delta=(ticks-clock->ticks)*console_config->pit_divisor+clock->count-count;
  if(delta<0) delta+=console_config->pit_divisor;
  clock->cycles+=delta;clock->ticks=ticks;clock->count=count;
  I386IrqRestore(irq);
  return (clock->cycles*5/1193182)&1;
}
U0 NativeKeyCursor(I64 ch)
{
  I386TextPut(&console_text,ch);ConsolePresent;
}
U0 NativeKeyDebugPoll()
{
  U32 irq=I386IrqSave;
  I64 i;
  try {
    for(i=0;i<64;i++) if(!(*console_config->input_poll)()) break;
    while(NativeKeyboardPump) {}
  } catch { I386IrqRestore(irq); }
  I386IrqRestore(irq);
}
U0 NativeKeyWait(Bool raw_cursor)
{//Keep cursor waits runnable; ordinary message waits retain the native parking flag.
  if(raw_cursor && IsRaw) LBtr(&Fs->task_flags,TASKf_AWAITING_MSG);
  Yield;
}
#define KEY_GET_LOCAL CNativeKeyClock clock;NativeKeyClockStart(&clock)
#define KEY_GET_PHASE NativeKeyClockPhase(&clock)
#define KEY_GET_CURSOR NativeKeyCursor
#define KEY_GET_DEBUG NativeIsDebugMode
#define KEY_GET_DEBUG_POLL NativeKeyDebugPoll
#define KEY_GET_WAIT NativeKeyWait(raw_cursor)
#include "/Kernel/KeyGetCore.HC"
Bool NativeKeyDevFilterKey(I64 ch,I64 sc)
{
  if(!Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) return FALSE;
  (*native_output_msg)(MSG_KEY_DOWN,ch,sc,0);
  return TRUE;
}
Bool NativeKeyDevFilterString(U8 *s)
{
  if(!Bt(&Fs->task_flags,TASKf_INPUT_FILTER_TASK)) return FALSE;
  while(*s) {
    (*native_output_msg)(MSG_KEY_DOWN,*s++,0,0);
    I386TaskBreakPoll;
  }
  return TRUE;
}
Bool NativeKeyDevConsoleKey(I64 ch,I64 sc)
{
  CDoc *doc=DocPut;
  Bool project;
  if(sc&SCF_KEY_DESC) return FALSE;
  project=NativeTerminalProjects(doc,NULL,sc);
  if(doc) DocPutKey(doc,ch,sc);
  if(project && !(sc&(SCF_CTRL|SCF_ALT))) I386TextPut(&console_text,ch);
  ConsolePresent;
  return FALSE;
}
Bool NativeKeyDevConsoleString(U8 *s)
{
  CDoc *doc=DocPut;
  Bool project=NativeTerminalProjects(doc,s);
  if(doc)DocPrintPartial(doc,"%s",s);
  if(project)I386TextWrite(&console_text,s);
  ConsolePresent;
  return FALSE;
}
U0 NativeKeyDevStart()
{
  if(native_keydev_ready) return;
  MemSet(&keydev,0,sizeof(CKeyDevGlbls));
  QueInit(&keydev.put_key_head);
  KeyDevAdd(&NativeKeyDevFilterKey,&NativeKeyDevFilterString,0x40000000,FALSE);
  KeyDevAdd(&NativeKeyDevConsoleKey,&NativeKeyDevConsoleString,0x80000000,TRUE);
  native_keydev_ready=TRUE;
}
