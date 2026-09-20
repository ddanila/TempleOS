//Retained single-owner VGA console and native command input.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/ConsoleRuntime.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/TextVga.HH"
#include "/Kernel/I386/Vga.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/ExceptRuntime.HH"
#include "/Kernel/I386/TaskBreak.HH"
#include "/Kernel/I386/DocLock.HH"
#include "/Kernel/I386/KernelSymbols.HH"
#include "/Kernel/FontStd.HC"
import Bool I386SchedYield(CI386Scheduler *scheduler);
import U0 HashAdd(CHash *entry,CHashTable *table);
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import Bool I386SchedWake(CI386Scheduler *scheduler,CI386Task *task);
import Bool I386SchedBlock(CI386Scheduler *scheduler);
import Bool I386KbcQueueGet(CI386KbcQueue *queue,U8 *data,U8 *status);
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
U8 *console_title="TempleOS i386\nHolyC console\n\n";
CI386ConsoleConfig *console_config;
CI386Text console_text;
CI386KeyboardState console_hotkeys;
CI386Task *console_break_task;
CI386KernelSymbol console_doc_exports[2];
U8 *console_planes;
U32 console_version=I386_CONSOLE_VERSION;
extern U0 ConsolePresent();
extern Bool ConsoleDisplay();
extern U0 ConsoleKeys(I64 unused);
extern U0 ConsoleSubmit(U8 *line);
extern Bool ConsoleSource(U8 *source,U8 *filename,I64 flags=0);
Bool ConsoleInit(CI386ConsoleConfig *config)
{
  CI386Task *task=I386TaskSelf;
  if(!task || !task->hash_table || console_config || !config || !config->heap || !config->compiler ||
      config->compiler->version!=I386_COMPILER_SERVICES_VERSION ||
      config->compiler->bytes!=sizeof(CI386CompilerServices) || !config->compiler->input || !config->compiler->break_poll ||
      !config->files || !config->includes || !config->types || !config->reader || !config->input) return FALSE;
  if(!I386KeyboardReadInit(config->reader,config->input)) return FALSE;
  I386KeyboardReset(&console_hotkeys);
  console_doc_exports[0].str="_DOC_LOCK";
  console_doc_exports[0].val=(&I386DocLock+0)(U64);
  console_doc_exports[1].str="_DOC_UNLOCK";
  console_doc_exports[1].val=(&I386DocUnlock+0)(U64);
  console_doc_exports[0].type=console_doc_exports[1].type=HTT_EXPORT_SYS_SYM;
  console_doc_exports[0].kind=console_doc_exports[1].kind=1;
  HashAdd(&console_doc_exports[0],task->hash_table);
  HashAdd(&console_doc_exports[1],task->hash_table);
  console_config=config; return TRUE;
}
Bool ConsoleCancelRead(CI386Task *task)
{
  if(!console_config || !console_config->reader) return FALSE;
  return I386KbcInputCancel(console_config->reader->input,task);
}
Bool ConsoleKeyIrq(U8 data,U8 status)
{//Called with IF clear; request only, never allocate, switch or throw here.
  if(!I386KeyboardBreakKey(&console_hotkeys,data,status) || !console_break_task) return FALSE;
  return I386TaskBreakRequest(console_break_task);
}
I64 Main(CI386ConsoleServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386ConsoleServices)) return 0;
  services->version=console_version; services->bytes=bytes;
  services->init=&ConsoleInit; services->display=&ConsoleDisplay; services->keys=&ConsoleKeys;
  services->cancel_read=&ConsoleCancelRead;
  services->cancel_wait=&I386TaskCancelWait; services->key_irq=&ConsoleKeyIrq;
  return 1;
}
Bool ConsoleDisplay()
{
  U8 palette[48];
  I64 color;
  if(!console_config || console_planes) return FALSE;
  console_planes=I386HeapAlloc(console_config->heap,153600,TRUE);
  if(!console_planes) KernelStop;
  for(color=0;color<16;color++) {
    palette[color*3]=0; palette[color*3+1]=0; palette[color*3+2]=0;
    if(color&4) palette[color*3]=42;
    if(color&2) palette[color*3+1]=42;
    if(color&1) palette[color*3+2]=42;
    if(color&8) {
      palette[color*3]+=21; palette[color*3+1]+=21; palette[color*3+2]+=21;
    }
    if(color==6) palette[color*3+1]=21;
  }
  I386VgaPalette(palette);
  if(!I386TextInit(&console_text,console_planes,sys_font_std)) KernelStop;
  I386TextWrite(&console_text,console_title);
  ConsolePresent;
  return TRUE;
}
U0 ConsoleKeys(I64 unused)
{//Single console/input owner. Each complete line is a recoverable compiler input.
  CI386KeyEvent event;
  U8 line[256];
  I64 length=0,decoded,ch,spaces,header_used;
  CI386Task *task=I386TaskSelf;
  CI386TaskSymbols *scope=task->symbol_state;
  //Fresh scheduler entries have IF clear. Devices and task services are ready;
  //allow timer/keyboard delivery during startup compilation and user execution.
  SetRFlags(GetRFlags|0x200);
  header_used=scope->heap->used;
  KernelLog("PUBLIC HEADERS begin\n");
  if(ConsoleSource("#include \"/Kernel/I386/PublicKernel.HH\"\n","ConsoleHeaders.HC",
      I386_INPUT_ATOMIC_DEFINES|CCF_JUST_LOAD)) KernelLog("PUBLIC HEADERS ok\n");
  else { ConsolePresent; KernelLog("PUBLIC HEADERS error\n"); KernelStop; }
  KernelLog("PUBLIC HEADERS MEMORY "); KernelHex(scope->heap->used-header_used); KernelLog("\n");
  KernelLog("STARTUP source begin\n");
  if(ConsoleSource("#include \"/Kernel/I386/StartOS.HC\"\n","ConsoleStartup.HC"))
    KernelLog("STARTUP source ok\n");
  else KernelLog("STARTUP source error\n");
  I386TextWrite(&console_text,"> "); ConsolePresent;
  KernelLog("DONE native kernel startup\n");
  while(1) {
    decoded=I386KeyboardRead(console_config->reader,&event,TRUE);
    if(decoded<0) {
      length=0;
      I386TextWrite(&console_text,"\nInput reset\n> ");
      ConsolePresent;
      KernelLog("INPUT RESET\n");
    } else if(decoded && event.type==2) {
      ch=event.ch;
      if(ch==3) {
        length=0; I386TextWrite(&console_text,"^C\n> ");
        KernelLog("INPUT CANCEL\n");
      } else if(ch==8) {
        if(length) { length--; I386TextPut(&console_text,8); }
      } else if(ch==10) {
        line[length]=0;
        KernelLog("INPUT LINE "); KernelLog(line); KernelLog("\n");
        I386TextPut(&console_text,10); ConsoleSubmit(line);
        length=0; I386TextWrite(&console_text,"> ");
      } else if(ch==9) {
        spaces=8-length%8;
        while(spaces-- && length<255) {
          line[length++]=32; I386TextPut(&console_text,32);
        }
      } else if(ch>=32 && ch<=255 && length<255) {
        line[length++]=ch; I386TextPut(&console_text,ch);
      }
      ConsolePresent;
    }
  }
}


#include "/Kernel/I386/Vga.HC"
#include "/Kernel/I386/Text.HC"
#include "/Kernel/I386/TextVga.HC"
#include "/Kernel/I386/ConsoleNumbers.HC"
#include "/Kernel/I386/ConsoleInput.HC"

U0 ConsolePresent()
{
  I64 rows=I386TextPresent(&console_text),i;
  U8 message[13],*prefix="VGA ROWS ";
  if(rows<0) KernelStop;
  if(rows) {
    for(i=0;i<9;i++) message[i]=prefix[i];
    message[9]='0'+rows/10; message[10]='0'+rows%10;
    message[11]=10; message[12]=0; KernelLog(message);
  }
}

#include "/Kernel/I386/KbcInputCancel.HC"

#include "/Kernel/I386/WaitCancel.HC"

#include "/Kernel/I386/KbcInputRead.HC"
#include "/Kernel/I386/ScanSet1.HC"
#include "/Kernel/I386/ScanChar.HC"
#include "/Kernel/I386/ScanState.HC"
#include "/Kernel/I386/KeyboardEvent.HC"
#include "/Kernel/I386/KeyboardRead.HC"

#include "/Kernel/I386/KeyboardBreak.HC"
#include "/Kernel/I386/TaskBreak.HC"

U0 I386DocBreakPoll()
{
  console_config->compiler->break_poll();
}
#include "/Kernel/I386/DocLock.HC"
