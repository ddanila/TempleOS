//Native kernel foundation. Resident HolyC compilation and source execution are pending.
#include "/Kernel/Types.HH"
#include "/Kernel/FontStd.HC"
#define TRUE 1
#define FALSE 0
#define U32_MAX 0xFFFFFFFF
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/BootMemory.HH"
#include "/Kernel/I386/BootDisk.HH"
#include "/Kernel/I386/RedSea.HH"
#include "/Kernel/I386/ModuleFile.HH"
#include "/Kernel/I386/A20.HH"
#include "/Kernel/I386/TaskPlatform.HH"
#include "/Kernel/I386/ExceptNative.HH"
#include "/Kernel/I386/Interrupt.HH"
#include "/Kernel/I386/Timer.HH"
#include "/Kernel/I386/Sleep.HH"
#include "/Kernel/I386/Vga.HH"
#include "/Kernel/I386/Text.HH"
#include "/Kernel/I386/KeyboardSetup.HH"
#include "/Kernel/I386/KeyboardRead.HH"
#include "/Kernel/I386/Kbc.HH"
#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/HashTable.HH"
#include "/Kernel/HashValue.HH"
#include "/Compiler/I386/InternalTypes.HH"
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/CompilerRuntime.HH"
class CI386KernelSymbol:CHashExport { U32 kind; };
import U0 i386_idle();
CI386Scheduler kernel_scheduler;
CI386Task kernel_root;
CI386Cpu kernel_cpu;
CI386Heap kernel_heap;
CI386Ata kernel_disk;
CI386RedSea kernel_volume;
CI386Timer kernel_timer;
CI386SleepQueue kernel_sleep;
CI386Text kernel_text;
CI386KbcInput kernel_input;
CI386KeyboardReader kernel_reader;
U8 kernel_gdt[40],kernel_idt[2048];
U8 *kernel_planes;
CI386OwnedTask *kernel_pulse;
CI386OwnedTask *kernel_keys;
I64 kernel_startup_count;
CHashTable *kernel_symbols;
CI386InternalTypes kernel_types;
CI386KernelSymbol kernel_exports[10];
CI386CompilerServices kernel_compiler;
U8 *kernel_compiler_image;
I64 kernel_compiler_size,kernel_compiler_span;
extern U0 KernelLog(U8 *text);
extern U0 KernelHex(U64 value);
extern U0 KernelStop();
extern U0 KernelIrq(CI386IrqFrame *frame);
extern U0 KernelFault(CI386ExceptionFrame *frame);
extern U0 KernelReport(CI386Task *task,I64 ch);
extern U0 KernelFatal(CI386Task *task,I64 status,I64 ch);
extern U0 KernelPulse(I64 unused);
extern U0 KernelDisplay();
extern U0 KernelStorage(CI386BootInfo *info);
extern U0 KernelStartup();
extern U0 KernelCompilerLoad();
extern U0 KernelCompilerProbe(I64 phase);
extern U0 KernelKeys(I64 unused);
extern U0 KernelSymbols();
extern U0 KernelBinding(CI386ModuleBinding *binding,U8 *name);
I64 Main(CI386BootInfo *info,I64 unused)
{
  CI386MemRange reserved,arena;
  CI386InterruptServices services;
  KernelLog("START native kernel\n");
  reserved.base=0x88000; reserved.size=32768;
  if(!I386BootArena(info,&reserved,1,&arena) || !(info->flags&2) ||
      info->extended_kib<128 || !I386A20Enable(FALSE) ||
      !I386BootArena(info,&reserved,1,&arena,TRUE) ||
      !I386HeapInit(&kernel_heap,arena.base,arena.size)) KernelStop;
  KernelLog("ARENA "); KernelHex(arena.base); KernelLog(" ");
  KernelHex(arena.size); KernelLog("\n");
  if(!I386TaskPlatformInit(&kernel_scheduler,&kernel_root,&kernel_cpu,
      kernel_gdt,0x88000,32768,&kernel_heap) ||
      !I386ExceptInstallNative(&KernelReport,&KernelFatal)) KernelStop;
  KernelStorage(info);
  I386PicInit;
  services.irq=&KernelIrq; services.exception=&KernelFault;
  if(!I386InterruptInstall(kernel_idt,256,&KernelStop,&services) ||
      !I386TimerInit(&kernel_timer,11932) ||
      !I386SleepInit(&kernel_sleep,&kernel_scheduler)) KernelStop;
  KernelSymbols;
  KernelCompilerLoad;
  KernelCompilerProbe(0);
  KernelStartup;
  if(!I386KbcInputInit(&kernel_input,&kernel_scheduler) ||
      !I386KeyboardReadInit(&kernel_reader,&kernel_input) || !I386KeyboardSetup) KernelStop;
  kernel_keys=I386TaskSpawn(&kernel_scheduler,&kernel_heap,8192,&KernelKeys,0,
    0x18,0x20,4096);
  if(!kernel_keys) KernelStop;
  kernel_pulse=I386TaskSpawn(&kernel_scheduler,&kernel_heap,8192,&KernelPulse,0,
    0x18,0x20,4096);
  if(!kernel_pulse) KernelStop;
  KernelLog("READY native kernel foundation\n");
  I386PicMask(0xFFFC);
  while(1) {
    if(kernel_root.next==&kernel_root) I386SchedIdle(&kernel_scheduler,&i386_idle);
    else I386SchedYield(&kernel_scheduler);
  }
}
U0 KernelLog(U8 *text)
{
  while(*text) OutU8(0xE9,*text++);
}
U0 KernelHex(U64 value)
{
  U8 *digits="0123456789ABCDEF";
  I64 i;
  for(i=60;i>=0;i-=4) OutU8(0xE9,digits[(value>>i)&15]);
}
U0 KernelStop()
{
  asm { CLI }
  KernelLog("FAIL native kernel\n");
  while(1) { asm { HLT } }
}
U0 KernelIrq(CI386IrqFrame *frame)
{
  U8 data,status;
  if(!I386PicAccept(frame->irq)) return;
  if(frame->irq==0) {
    if(!I386TimerStep(&kernel_timer) || !I386SleepTick(&kernel_sleep)) KernelStop;
  }
  if(frame->irq==1 && I386KbcRead(&data,&status))
    I386KbcInputPut(&kernel_input,data,status);
  I386PicEoi(frame->irq);
}
U0 KernelFault(CI386ExceptionFrame *frame)
{
  KernelLog("FAULT "); KernelHex(frame->vector); KernelLog(" ");
  KernelHex(frame->eip); KernelLog("\n"); KernelStop;
}
U0 KernelReport(CI386Task *task,I64 ch)
{
  KernelLog("THROW "); KernelHex(ch); KernelLog("\n");
}
U0 KernelFatal(CI386Task *task,I64 status,I64 ch)
{
  KernelLog("UNHANDLED "); KernelHex(status); KernelLog(" ");
  KernelHex(ch); KernelLog("\n"); KernelStop;
}
U0 KernelPulse(I64 unused)
{
  I64 pulses=0;
  while(1) {
    if(!I386SleepTicks(&kernel_sleep,25)) KernelStop;
    if(pulses<2) {
      pulses++;
      KernelLog("TICK "); KernelHex(I386TimerTicks(&kernel_timer)); KernelLog("\n");
      if(pulses==2) {
        KernelCompilerProbe(1);
        KernelLog("DONE native kernel startup\n");
      }
    }
  }
}
U0 KernelDisplay()
{
  U8 palette[48];
  I64 color;
  kernel_planes=I386HeapAlloc(&kernel_heap,153600,TRUE);
  if(!kernel_planes) KernelStop;
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
  if(!I386TextInit(&kernel_text,kernel_planes,sys_font_std)) KernelStop;
  I386TextWrite(&kernel_text,"TempleOS i386\nKeyboard console\n\n> ");
  I386VgaPresent(kernel_planes);
}
#include "/Kernel/I386/BootMemory.HC"
#include "/Kernel/I386/A20.HC"
#include "/Kernel/I386/ModuleFile.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
#include "/Kernel/I386/ExceptRuntime.HC"
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Task.HC"
#include "/Kernel/I386/Segments.HC"
#include "/Kernel/I386/Gdt.HC"
#include "/Kernel/I386/TaskPlatform.HC"
#include "/Kernel/I386/ExceptNative.HC"
#include "/Kernel/I386/Idt.HC"
#include "/Kernel/I386/Interrupt.HC"
#include "/Kernel/I386/PicPit.HC"
#include "/Kernel/I386/Timer.HC"
#include "/Kernel/I386/Sleep.HC"
#include "/Kernel/I386/Vga.HC"
#include "/Kernel/I386/Text.HC"
#include "/Kernel/I386/Kbc.HC"
#include "/Kernel/I386/KbcQueue.HC"
#include "/Kernel/I386/KbcInput.HC"
#include "/Kernel/I386/ScanSet1.HC"
#include "/Kernel/I386/ScanChar.HC"
#include "/Kernel/I386/ScanState.HC"
#include "/Kernel/I386/KeyboardEvent.HC"
#include "/Kernel/I386/KeyboardRead.HC"
#include "/Kernel/I386/KeyboardSetup.HC"
#include "/Kernel/I386/Hash.HC"
#include "/Kernel/I386/HashTable.HC"
#include "/Kernel/HashValue.HC"
#include "/Compiler/I386/SymbolAlloc.HC"
#include "/Compiler/I386/SymbolDelete.HC"
#include "/Compiler/I386/InternalTypes.HC"
#include "/Kernel/CharBitmaps.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"


U0 KernelKeys(I64 unused)
{//Single console/input owner. Lines are collected here; native compilation is pending.
  CI386KeyEvent event;
  U8 line[256];
  I64 length=0,decoded,ch,spaces;
  while(1) {
    decoded=I386KeyboardRead(&kernel_reader,&event);
    if(decoded<0) {
      length=0;
      I386TextWrite(&kernel_text,"\nInput reset\n> ");
      I386VgaPresent(kernel_planes);
      KernelLog("INPUT RESET\n");
    } else if(decoded && event.type==2) {
      ch=event.ch;
      if(ch==3) {
        length=0; I386TextWrite(&kernel_text,"^C\n> ");
        KernelLog("INPUT CANCEL\n");
      } else if(ch==8) {
        if(length) { length--; I386TextPut(&kernel_text,8); }
      } else if(ch==10) {
        line[length]=0;
        KernelLog("INPUT LINE "); KernelLog(line); KernelLog("\n");
        length=0; I386TextWrite(&kernel_text,"\n> ");
      } else if(ch==9) {
        spaces=8-length%8;
        while(spaces-- && length<255) {
          line[length++]=32; I386TextPut(&kernel_text,32);
        }
      } else if(ch>=32 && ch<=255 && length<255) {
        line[length++]=ch; I386TextPut(&kernel_text,ch);
      }
      I386VgaPresent(kernel_planes);
    }
  }
}

U0 KernelStorage(CI386BootInfo *info)
{//Initial profile: BIOS drive 0x80 is primary IDE master; boot I/O owns the channel.
  CI386BootDiskInfo *boot=I386_BOOT_DISK_INFO_ADDRESS;
  CI386RedSeaEntry entry;
  U8 *buffer;
  CCmpCtrl *cc;
  CLexFile *file;
  I64 i,ch,characters=0,lines=0,used=kernel_heap.used,allocations=kernel_heap.allocations,transient;
  U32 hash=2166136261,lex_hash=2166136261;
  if(boot->magic!=I386_BOOT_DISK_INFO_MAGIC || boot->version!=1 ||
      boot->bios_drive!=0x80 || boot->volume_start<=(info->stage_end-info->stage_begin)/512 ||
      !I386AtaIdentify(&kernel_disk,0,0) ||
      !I386RedSeaMount(&kernel_volume,&kernel_disk,boot->volume_start)) KernelStop;
  KernelLog("REDSEA "); KernelHex(kernel_volume.start); KernelLog(" ");
  KernelHex(kernel_volume.sectors); KernelLog("\n");
  if(I386RedSeaFind(&kernel_volume,kernel_volume.root,"Kernel",&entry)!=1 ||
      !(entry.attr&0x10) || I386RedSeaFind(&kernel_volume,entry.block,"I386",&entry)!=1 ||
      !(entry.attr&0x10) || I386RedSeaFind(&kernel_volume,entry.block,"Kernel.HC",&entry)!=1 ||
      (entry.attr&0x310) || entry.size<1) KernelStop;
  if(entry.size>0xFFFFFFFE) KernelStop;
  buffer=I386HeapAlloc(&kernel_heap,entry.size+1);
  cc=I386HeapAlloc(&kernel_heap,sizeof(CCmpCtrl),TRUE);
  if(!buffer || !cc || I386RedSeaRead(&kernel_volume,&entry,0,buffer,entry.size)!=entry.size) KernelStop;
  buffer[entry.size]=0;
  for(i=0;i<entry.size;i++) hash=(hash^buffer[i])*16777619;
  KernelLog("SOURCE "); KernelHex(entry.size); KernelLog(" ");
  KernelHex(hash); KernelLog("\n");
  CmpCtrlSeed(cc,0,0,char_bmp_alpha_numeric);
  file=I386LexFilePush(&kernel_heap,cc);
  if(!file) KernelStop;
  LexFileSeed(file,buffer); cc->cur_buf_ptr=buffer;
  while(ch=I386LexRawChar(&kernel_heap,cc,&lines)) {
    if(ch<0) KernelStop;
    lex_hash=(lex_hash^ch)*16777619; characters++;
  }
  if(cc->cur_buf_ptr!=buffer+entry.size || file->line_num!=lines+1) KernelStop;
  transient=kernel_heap.used-used;
  if(!I386LexFilePop(&kernel_heap,cc) || !I386HeapFree(&kernel_heap,cc) ||
      kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
  KernelLog("LEX_SOURCE "); KernelHex(characters); KernelLog(" "); KernelHex(lines); KernelLog(" ");
  KernelHex(lex_hash); KernelLog(" "); KernelHex(transient); KernelLog("\n");
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"

U0 KernelStartup()
{//Startup owns ATA and the heap with IF clear. No module callbacks may survive return.
  CI386RedSeaEntry file;
  CI386ModuleBinding bindings[3];
  U8 *image;
  I64 (*entry)();
  I64 used=kernel_heap.used,allocations=kernel_heap.allocations;
  I64 transient,after,result;
  if(I386RedSeaFind(&kernel_volume,kernel_volume.root,"Modules",&file)!=1 ||
      !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"I386",&file)!=1 ||
      !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"Startup.t32m",&file)!=1)
    KernelStop;
  KernelBinding(&bindings[0],"KernelLog");
  KernelBinding(&bindings[1],"KernelDisplay");
  KernelBinding(&bindings[2],"kernel_startup_count");
  image=I386RedSeaLoadBound(&kernel_volume,&file,&kernel_heap,"Main",bindings,3);
  if(!image || kernel_heap.allocations!=allocations+1) KernelStop;
  transient=kernel_heap.used-used;
  entry=image;
  result=(*entry)();
  after=kernel_heap.used; allocations=kernel_heap.allocations;
  if(result!=1 || kernel_startup_count!=1 || !kernel_planes || transient<=0 ||
      !I386HeapFree(&kernel_heap,image) || kernel_heap.used!=after-transient ||
      kernel_heap.allocations!=allocations-1 || !I386HeapValid(&kernel_heap)) KernelStop;
  KernelLog("MODULE "); KernelHex(result); KernelLog(" ");
  KernelHex(transient); KernelLog("\n");
}

U0 KernelSymbols()
{//Boot-only private export index, using the shared public hash-record prefix.
//These records describe loader bindings; they are not compiler CHashFun objects.
  I64 i,used;
  CHashClass *record;
  kernel_symbols=I386HashTableNew(&kernel_heap,8);
  if(!kernel_symbols) KernelStop;
  used=kernel_heap.used;
  if(!I386InternalTypesInit(&kernel_types,&kernel_heap)) KernelStop;
  kernel_symbols->next=kernel_types.table;
  for(i=0;i<INTERNAL_TYPES_NUM;i++) {
    record=HashFind(internal_types_table[i].name,kernel_symbols,HTT_INTERNAL_TYPE);
    if(!record || record->raw_type!=internal_types_table[i].type ||
        record->size!=internal_types_table[i].size || record[1].size!=4) KernelStop;
  }
  if(HashFind("Bool",kernel_symbols,HTT_INTERNAL_TYPE)!=kernel_types.by_raw[RT_I8] ||
      HashFind("F64",kernel_symbols,HTT_INTERNAL_TYPE)!=kernel_types.by_raw[RT_F64]) KernelStop;
  KernelLog("TYPES "); KernelHex(INTERNAL_TYPES_NUM); KernelLog(" ");
  KernelHex(kernel_heap.used-used); KernelLog("\n");
  kernel_exports[0].str="KernelLog"; kernel_exports[0].kind=1;
  kernel_exports[0].val=(&KernelLog+0)(U64);
  kernel_exports[1].str="KernelDisplay"; kernel_exports[1].kind=1;
  kernel_exports[1].val=(&KernelDisplay+0)(U64);
  kernel_exports[2].str="kernel_startup_count"; kernel_exports[2].kind=3;
  kernel_exports[2].val=(&kernel_startup_count+0)(U64);
  kernel_exports[3].str="I386LexRawChar"; kernel_exports[3].kind=1;
  kernel_exports[3].val=(&I386LexRawChar+0)(U64);
  kernel_exports[4].str="I386LexSourceRead"; kernel_exports[4].kind=1;
  kernel_exports[4].val=(&I386LexSourceRead+0)(U64);
  kernel_exports[5].str="char_bmp_hex_numeric"; kernel_exports[5].kind=3;
  kernel_exports[5].val=(char_bmp_hex_numeric+0)(U64);
  kernel_exports[6].str="char_bmp_dec_numeric"; kernel_exports[6].kind=3;
  kernel_exports[6].val=(char_bmp_dec_numeric+0)(U64);
  kernel_exports[7].str="char_bmp_non_eol"; kernel_exports[7].kind=3;
  kernel_exports[7].val=(char_bmp_non_eol+0)(U64);
  kernel_exports[8].str="HashFind"; kernel_exports[8].kind=1;
  kernel_exports[8].val=(&HashFind+0)(U64);
  kernel_exports[9].str="StrCmp"; kernel_exports[9].kind=1;
  kernel_exports[9].val=(&StrCmp+0)(U64);
  for(i=0;i<10;i++) { kernel_exports[i].type=HTT_EXPORT_SYS_SYM; HashAdd(&kernel_exports[i],kernel_symbols); }
}
U0 KernelBinding(CI386ModuleBinding *binding,U8 *name)
{
  CI386KernelSymbol *symbol=HashFind(name,kernel_symbols,HTT_EXPORT_SYS_SYM);
  I64 address;
  if(!symbol) KernelStop;
  address=HashVal(symbol);
  if(address<=0 || address>0xFFFFFFFF) KernelStop;
  binding->name=symbol->str; binding->kind=symbol->kind; binding->address=address;
}

U0 KernelCompilerLoad()
{//Boot owns ATA/heap with IF clear. Publish only a validated, retained interface.
  CI386RedSeaEntry file;
  CI386ModuleBinding bindings[7];
  CI386CompilerServices candidate;
  I64 (*entry)(CI386CompilerServices *services,I64 bytes);
  I64 used=kernel_heap.used,allocations=kernel_heap.allocations,size=0,accepted=0;
  U64 base,string_address,number_address,char_address,punct_address,ident_address;
  U8 *image=0,*reason="load";
  if(kernel_compiler_image || kernel_compiler.version) KernelStop;
  candidate.version=0; candidate.bytes=0; candidate.string_chunk=0; candidate.number_token=0; candidate.char_token=0; candidate.punct_token=0; candidate.ident_scan=0;
  if(I386RedSeaFind(&kernel_volume,kernel_volume.root,"Modules",&file)!=1 ||
      !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"I386",&file)!=1 ||
      !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"CompilerRuntime.t32m",&file)!=1)
    KernelStop;
  KernelBinding(&bindings[0],"I386LexRawChar");
  KernelBinding(&bindings[1],"I386LexSourceRead");
  KernelBinding(&bindings[2],"char_bmp_hex_numeric");
  KernelBinding(&bindings[3],"char_bmp_dec_numeric");
  KernelBinding(&bindings[4],"char_bmp_non_eol");
  KernelBinding(&bindings[5],"HashFind"); KernelBinding(&bindings[6],"StrCmp");
  image=I386RedSeaLoadBound(&kernel_volume,&file,&kernel_heap,"Main",bindings,7);
  if(image) {
    reason="api"; size=I386HeapSize(&kernel_heap,image); base=(image+0)(U64);
    if(base>=0x110000 && size>8 && kernel_heap.allocations==allocations+1) {
      entry=image;
      accepted=(*entry)(&candidate,sizeof(CI386CompilerServices));
      string_address=(candidate.string_chunk+0)(U64);
      number_address=(candidate.number_token+0)(U64);
      char_address=(candidate.char_token+0)(U64);
      punct_address=(candidate.punct_token+0)(U64);
      ident_address=(candidate.ident_scan+0)(U64);
      if(candidate.version!=I386_COMPILER_SERVICES_VERSION || candidate.bytes!=sizeof(CI386CompilerServices) ||
          string_address<base+8 || string_address>=base+size ||
          number_address<base+8 || number_address>=base+size ||
          char_address<base+8 || char_address>=base+size ||
          punct_address<base+8 || punct_address>=base+size ||
          ident_address<base+8 || ident_address>=base+size) accepted=0;
    }
  }
  if(accepted!=1) {
    if(image && !I386HeapFree(&kernel_heap,image)) KernelStop;
    if(kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
    KernelLog("RUNTIME REJECT "); KernelLog(reason); KernelLog(" reclaimed\n"); KernelStop;
  }
  kernel_compiler.version=candidate.version; kernel_compiler.bytes=candidate.bytes;
  kernel_compiler.string_chunk=candidate.string_chunk; kernel_compiler.number_token=candidate.number_token;
  kernel_compiler.char_token=candidate.char_token; kernel_compiler.punct_token=candidate.punct_token;
  kernel_compiler.ident_scan=candidate.ident_scan;
  kernel_compiler_image=image; kernel_compiler_size=size; kernel_compiler_span=kernel_heap.used-used;
  KernelLog("RUNTIME "); KernelHex((image+0)(U64)); KernelLog(" ");
  KernelHex(size); KernelLog(" "); KernelHex(kernel_compiler_span); KernelLog(" ");
  KernelHex(string_address); KernelLog(" "); KernelHex(number_address); KernelLog(" "); KernelHex(char_address); KernelLog(" "); KernelHex(punct_address); KernelLog(" "); KernelHex(ident_address); KernelLog("\n");
}
U0 KernelCompilerProbe(I64 phase)
{//Exercise retained module code before startup and after task/IRQ activity.
  CCmpCtrl cc; CLexFile file;
  U8 input[10],output[4],ident[5],*bytes;
  CHash *ident_entry;
  I64 i,ch,lines=0,used=kernel_heap.used,allocations=kernel_heap.allocations;
  Bool done=FALSE;
  U64 value;
  if(!kernel_compiler_image || I386HeapSize(&kernel_heap,kernel_compiler_image)!=kernel_compiler_size ||
      kernel_compiler.version!=I386_COMPILER_SERVICES_VERSION) KernelStop;
  bytes=&cc; for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=&file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  input[0]='0'; input[1]='.'; input[2]='0'; input[3]='0'; input[4]='0'; input[5]='1'; input[6]=';'; input[7]=0;
  CmpCtrlSeed(&cc,CCF_DONT_FREE_BUF,kernel_symbols,char_bmp_alpha_numeric);
  LexFileSeed(&file,input); cc.lex_include_stk=&file; cc.cur_buf_ptr=input;
  ch=I386LexRawChar(&kernel_heap,&cc,&lines);
  if(kernel_compiler.number_token(&kernel_heap,&cc,ch,&lines)!=TK_F64 ||
      cc.cur_f64(U64)!=0x3F1A36E2EB1C432D || cc.last_U16!=';' || cc.cur_buf_ptr!=input+7) KernelStop;
  value=cc.cur_f64(U64);
  input[0]=92; input[1]='x'; input[2]='4'; input[3]='1'; input[4]=34; input[5]=';'; input[6]=0;
  cc.flags=CCF_DONT_FREE_BUF|CCF_IN_QUOTES; cc.dollar_cnt=0;
  LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(kernel_compiler.string_chunk(&kernel_heap,&cc,output,4,&done,&lines)!=2 || !done ||
      output[0]!='A' || output[1] || cc.cur_buf_ptr!=input+5 || lines ||
      kernel_heap.used!=used || kernel_heap.allocations!=allocations ||
      I386HeapSize(&kernel_heap,kernel_compiler_image)!=kernel_compiler_size || !I386HeapValid(&kernel_heap)) KernelStop;
  input[0]=92; input[1]='x'; input[2]='4'; input[3]='1'; input[4]='B'; input[5]=39; input[6]=59; input[7]=0;
  cc.flags=CCF_DONT_FREE_BUF; LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(kernel_compiler.char_token(&kernel_heap,&cc,&lines)!=TK_CHAR_CONST ||
      cc.cur_i64!=0x4241 || cc.last_U16!=59 || cc.cur_buf_ptr!=input+7 || lines ||
      kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
  input[0]='/'; input[1]='x'; input[2]=10; input[3]='<'; input[4]='<'; input[5]='='; input[6]=';'; input[7]=0;
  cc.flags=CCF_DONT_FREE_BUF; LexFileSeed(&file,input); cc.cur_buf_ptr=input;
  if(kernel_compiler.punct_token(&kernel_heap,&cc,'/',&lines)!=-2 || lines!=1) KernelStop;
  ch=I386LexRawChar(&kernel_heap,&cc,&lines);
  if(kernel_compiler.punct_token(&kernel_heap,&cc,ch,&lines)!=TK_SHL_EQU ||
      cc.last_U16!=59 || cc.cur_buf_ptr!=input+7 || lines!=1 ||
      kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
  input[0]=';'; input[1]=0;
  cc.flags=CCF_DONT_FREE_BUF|CCF_USE_LAST_U16; cc.last_U16=';';
  LexFileSeed(&file,input); cc.cur_buf_ptr=input+1;
  if(!I386LexIncludeCopy(&kernel_heap,&cc,"Probe","I64i",TRUE) ||
      !(cc.lex_include_stk->flags&LFSF_DEFINE) || cc.lex_include_stk->next!=&file) KernelStop;
  ch=I386LexRawChar(&kernel_heap,&cc,&lines);
  if(kernel_compiler.ident_scan(&kernel_heap,&cc,ch,ident,5,&ident_entry,&lines)!=5 ||
      ident_entry!=kernel_types.by_raw[RT_I64] || cc.local_var_entry ||
      ident[0]!='I' || ident[1]!='6' || ident[2]!='4' || ident[3]!='i' || ident[4] ||
      cc.token!=TK_SHL_EQU || cc.last_U16!=59 || cc.cur_buf_ptr!=input+1 || cc.lex_include_stk!=&file ||
      kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
  KernelLog("RUNTIME PROBE "); KernelHex(phase); KernelLog(" ");
  KernelHex(value); KernelLog(" "); KernelHex(output[0]); KernelLog(" "); KernelHex(cc.cur_i64); KernelLog(" "); KernelHex(cc.token); KernelLog(" "); KernelHex(ident_entry(CHashClass *)->size); KernelLog("\n");
}
