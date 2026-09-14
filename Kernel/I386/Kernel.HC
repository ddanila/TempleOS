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
#include "/Kernel/I386/FileRead.HH"
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
#include "/Compiler/I386/Keywords.HH"
#include "/Compiler/ControlInit.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/CompilerRuntime.HH"
#include "/Kernel/I386/CompilerProbe.HH"
#include "/Kernel/I386/FileRuntime.HH"
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
CI386Keywords kernel_keywords;
CI386KernelSymbol kernel_exports[35];
U8 kernel_export_kinds[35]={1,1,3,1,1,3,3,3,1,1,1,1,1,1,1,1,1,3,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1};
CI386CompilerServices kernel_compiler;
CI386FileServices kernel_files;
U8 *kernel_file_image;
I64 kernel_file_size;
CFilePathContext kernel_paths;
CI386FileVolumes kernel_volumes;
CI386LexFileContext kernel_file_context;
CI386LexIncludeService kernel_file_include;
U8 *kernel_compiler_image;
I64 kernel_compiler_size,kernel_compiler_span;
U8 *kernel_probe_image;
I64 kernel_probe_size,kernel_probe_span;
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
extern U0 KernelFileLoad();
extern U8 *KernelServiceLoad(U8 *path,U8 *label,CI386ModuleBinding *bindings,I64 count,
  U8 *record,I64 bytes,U32 version);
extern Bool KernelServiceCheck(U8 *image,I64 size,U8 *record,I64 bytes,U32 version);
extern U0 KernelServiceLog(U8 *label,U8 *image,I64 size,I64 span,U8 *record,I64 bytes);
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
  KernelFileLoad;
  KernelCompilerProbe(0);
  KernelStartup;
  if(!kernel_files.bind(&kernel_scheduler,&kernel_volume)) KernelStop;
  KernelLog("STORAGE TASK BOUND\n");
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
#include "/Kernel/I386/ModuleFileSingle.HC"
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
#include "/Compiler/I386/Keywords.HC"
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
  U8 *buffer,empty[1];
  CCmpCtrl *cc;
  CLexFile *file;
  I64 size=0,i,ch,characters=0,lines=0,used=kernel_heap.used,allocations=kernel_heap.allocations,transient;
  U32 hash=2166136261,lex_hash=2166136261;
  if(boot->magic!=I386_BOOT_DISK_INFO_MAGIC || boot->version!=1 ||
      boot->bios_drive!=0x80 || boot->volume_start<=(info->stage_end-info->stage_begin)/512 ||
      !I386AtaIdentify(&kernel_disk,0,0) ||
      !I386RedSeaMount(&kernel_volume,&kernel_disk,boot->volume_start)) KernelStop;
  KernelLog("REDSEA "); KernelHex(kernel_volume.start); KernelLog(" ");
  KernelHex(kernel_volume.sectors); KernelLog("\n");
  buffer=I386RedSeaFileRead(&kernel_volume,&kernel_heap,kernel_volume.root,"/Kernel/I386/Kernel.HC",&size);
  cc=I386HeapAlloc(&kernel_heap,sizeof(CCmpCtrl),TRUE);
  if(!buffer || !cc || size<1) KernelStop;
  for(i=0;i<size;i++) hash=(hash^buffer[i])*16777619;
  KernelLog("SOURCE "); KernelHex(size); KernelLog(" ");
  KernelHex(hash); KernelLog("\n");
  empty[0]=0;
  CmpCtrlSeed(cc,CCF_DONT_FREE_BUF,0,char_bmp_alpha_numeric);
  file=I386LexFilePush(&kernel_heap,cc);
  if(!file) KernelStop;
  LexFileSeed(file,empty); cc->cur_buf_ptr=empty;
  if(!I386LexIncludeTake(&kernel_heap,cc,"/Kernel/I386/Kernel.HC",buffer)) KernelStop;
  transient=kernel_heap.used-used;
  while(ch=I386LexRawChar(&kernel_heap,cc,&lines)) {
    if(ch<0 || cc->lex_include_stk==file || cc->lex_include_stk->line_num!=lines+1) KernelStop;
    lex_hash=(lex_hash^ch)*16777619; characters++;
  }
  if(cc->lex_include_stk!=file || cc->cur_buf_ptr!=empty || file->line_num!=1 ||
      I386HeapSize(&kernel_heap,buffer)!=-1 || kernel_heap.allocations!=allocations+2) KernelStop;
  if(!I386LexFilePop(&kernel_heap,cc) || !I386HeapFree(&kernel_heap,cc) ||
      kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
  KernelLog("LEX_SOURCE "); KernelHex(characters); KernelLog(" "); KernelHex(lines); KernelLog(" ");
  KernelHex(lex_hash); KernelLog(" "); KernelHex(transient); KernelLog("\n");
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/FileRead.HC"

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
  U8 *addresses[35],*names="KernelLog\0KernelDisplay\0kernel_startup_count\0I386LexRawChar\0I386LexSourceRead\0char_bmp_hex_numeric\0char_bmp_dec_numeric\0char_bmp_non_eol\0HashFind\0StrCmp\0I386HeapAlloc\0I386HeapFree\0I386HeapSize\0I386IrqSave\0I386IrqRestore\0I386LexIncludeCopy\0HashAdd\0char_bmp_non_eol_white_space\0KernelHex\0KernelStop\0I386HeapValid\0char_bmp_alpha_numeric\0I386RedSeaFind\0I386RedSeaResolve\0I386RedSeaReadAll\0I386LexIncludeTake\0I386RedSeaBegin\0I386RedSeaEnd\0I386RedSeaValid\0I386AtaIdentifyPolled\0I386AtaTransfer\0I386AtaFlushPolled\0I386SchedBlock\0I386SchedWake\0I386SchedYield\0";
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
  used=kernel_heap.used;
  if(!I386KeywordsInit(&kernel_keywords,&kernel_heap)) KernelStop;
  kernel_types.table->next=kernel_keywords.table;
  if(HashFind("F64",kernel_symbols,HTG_TYPE_MASK)!=kernel_types.by_raw[RT_F64]) KernelStop;
  KernelLog("KEYWORDS "); KernelHex(COMPILER_KEYWORDS_NUM); KernelLog(" "); KernelHex(kernel_heap.used-used); KernelLog("\n");
  addresses[0]=&KernelLog;
  addresses[1]=&KernelDisplay;
  addresses[2]=&kernel_startup_count;
  addresses[3]=&I386LexRawChar;
  addresses[4]=&I386LexSourceRead;
  addresses[5]=char_bmp_hex_numeric;
  addresses[6]=char_bmp_dec_numeric;
  addresses[7]=char_bmp_non_eol;
  addresses[8]=&HashFind;
  addresses[9]=&StrCmp;
  addresses[10]=&I386HeapAlloc;
  addresses[11]=&I386HeapFree;
  addresses[12]=&I386HeapSize;
  addresses[13]=&I386IrqSave;
  addresses[14]=&I386IrqRestore;
  addresses[15]=&I386LexIncludeCopy;
  addresses[16]=&HashAdd;
  addresses[17]=char_bmp_non_eol_white_space;
  addresses[18]=&KernelHex;
  addresses[19]=&KernelStop;
  addresses[20]=&I386HeapValid;
  addresses[21]=char_bmp_alpha_numeric;
  addresses[22]=&I386RedSeaFind;
  addresses[23]=&I386RedSeaResolve;
  addresses[24]=&I386RedSeaReadAll;
  addresses[25]=&I386LexIncludeTake;
  addresses[26]=&I386RedSeaBegin;
  addresses[27]=&I386RedSeaEnd;
  addresses[28]=&I386RedSeaValid;
  addresses[29]=&I386AtaIdentifyPolled;
  addresses[30]=&I386AtaTransfer;
  addresses[31]=&I386AtaFlushPolled;
  addresses[32]=&I386SchedBlock;
  addresses[33]=&I386SchedWake;
  addresses[34]=&I386SchedYield;
  for(i=0;i<35;i++) {
    kernel_exports[i].str=names; kernel_exports[i].kind=kernel_export_kinds[i];
    kernel_exports[i].val=(addresses[i]+0)(U64); kernel_exports[i].type=HTT_EXPORT_SYS_SYM;
    HashAdd(&kernel_exports[i],kernel_symbols);
    while(*names) names++;
    names++;
  }
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
  CI386ModuleBinding bindings[15];
  I64 used=kernel_heap.used;
  if(kernel_compiler_image || kernel_compiler.version) KernelStop;
  KernelBinding(&bindings[0],"I386LexRawChar");
  KernelBinding(&bindings[1],"I386LexSourceRead");
  KernelBinding(&bindings[2],"char_bmp_hex_numeric");
  KernelBinding(&bindings[3],"char_bmp_dec_numeric");
  KernelBinding(&bindings[4],"char_bmp_non_eol");
  KernelBinding(&bindings[5],"HashFind"); KernelBinding(&bindings[6],"StrCmp");
  KernelBinding(&bindings[7],"I386HeapAlloc");
  KernelBinding(&bindings[8],"I386HeapFree");
  KernelBinding(&bindings[9],"I386HeapSize");
  KernelBinding(&bindings[10],"I386IrqSave");
  KernelBinding(&bindings[11],"I386IrqRestore");
  KernelBinding(&bindings[12],"I386LexIncludeCopy");
  KernelBinding(&bindings[13],"HashAdd");
  KernelBinding(&bindings[14],"char_bmp_non_eol_white_space");
  kernel_compiler_image=KernelServiceLoad("/Modules/I386/CompilerRuntime.t32m","RUNTIME ",
    bindings,15,&kernel_compiler,sizeof(CI386CompilerServices),I386_COMPILER_SERVICES_VERSION);
  kernel_compiler_size=I386HeapSize(&kernel_heap,kernel_compiler_image);
  kernel_compiler_span=kernel_heap.used-used;
}
U0 KernelCompilerProbe(I64 phase)
{//Load once with boot disk ownership; the task call performs no disk I/O.
  CI386RedSeaEntry file; CI386ModuleBinding bindings[13]; CI386CompilerProbe probe;
  I64 (*entry)(CI386CompilerProbe *probe,I64 bytes);
  I64 used=kernel_heap.used,allocations=kernel_heap.allocations;
  U32 flags;
  if(phase==0) {
    if(kernel_probe_image) KernelStop;
    KernelBinding(&bindings[0],"KernelLog"); KernelBinding(&bindings[1],"KernelHex");
    KernelBinding(&bindings[2],"KernelStop"); KernelBinding(&bindings[3],"I386HeapSize");
    KernelBinding(&bindings[4],"I386HeapFree"); KernelBinding(&bindings[5],"I386HeapValid");
    KernelBinding(&bindings[6],"I386IrqSave"); KernelBinding(&bindings[7],"I386IrqRestore");
    KernelBinding(&bindings[8],"I386LexRawChar"); KernelBinding(&bindings[9],"I386LexIncludeCopy");
    KernelBinding(&bindings[10],"HashAdd"); KernelBinding(&bindings[11],"StrCmp");
    KernelBinding(&bindings[12],"char_bmp_alpha_numeric");
    if(I386RedSeaFind(&kernel_volume,kernel_volume.root,"Modules",&file)!=1 ||
        !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"I386",&file)!=1 ||
        !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"CompilerProbe.t32m",&file)!=1) KernelStop;
    kernel_probe_image=I386RedSeaLoadBound(&kernel_volume,&file,&kernel_heap,"Main",bindings,13);
    if(!kernel_probe_image) {
      if(kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
      KernelLog("PROBE REJECT load reclaimed\n"); KernelStop;
    }
    kernel_probe_size=I386HeapSize(&kernel_heap,kernel_probe_image);
    kernel_probe_span=kernel_heap.used-used;
    if((kernel_probe_image+0)(U64)<0x110000 || kernel_probe_size<8 || kernel_heap.allocations!=allocations+1) KernelStop;
  } else if(phase!=1 || !kernel_probe_image) KernelStop;
  if(I386HeapSize(&kernel_heap,kernel_probe_image)!=kernel_probe_size) KernelStop;
  used=kernel_heap.used; allocations=kernel_heap.allocations;
  probe.version=I386_COMPILER_PROBE_VERSION; probe.bytes=sizeof(CI386CompilerProbe);
  probe.heap=&kernel_heap; probe.compiler=&kernel_compiler; probe.symbols=kernel_symbols;
  probe.i64_type=kernel_types.by_raw[RT_I64]; probe.runtime_image=kernel_compiler_image;
  probe.runtime_size=kernel_compiler_size; probe.phase=phase;
  probe.disk_include=&kernel_file_include;
  entry=kernel_probe_image;
  if((*entry)(&probe,sizeof(CI386CompilerProbe))!=1) {
    flags=I386IrqSave;
    if(!I386HeapFree(&kernel_heap,kernel_probe_image)) KernelStop;
    kernel_probe_image=0;
    I386IrqRestore(flags);
    if(kernel_heap.used!=used-kernel_probe_span || kernel_heap.allocations!=allocations-1 || !I386HeapValid(&kernel_heap)) KernelStop;
    KernelLog("PROBE REJECT api reclaimed\n"); KernelStop;
  }
  if(kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
  if(!phase) {
    KernelLog("PROBE MODULE "); KernelHex((kernel_probe_image+0)(U64)); KernelLog(" ");
    KernelHex(kernel_probe_size); KernelLog(" "); KernelHex(kernel_probe_span); KernelLog("\n");
  } else {
    flags=I386IrqSave;
    if(!I386HeapFree(&kernel_heap,kernel_probe_image)) KernelStop;
    kernel_probe_image=0;
    I386IrqRestore(flags);
    if(kernel_heap.used!=used-kernel_probe_span || kernel_heap.allocations!=allocations-1 ||
        I386HeapSize(&kernel_heap,kernel_compiler_image)!=kernel_compiler_size ||
        I386HeapSize(&kernel_heap,kernel_file_image)!=kernel_file_size || !I386HeapValid(&kernel_heap)) KernelStop;
    KernelLog("PROBE RELEASE "); KernelHex(kernel_probe_size); KernelLog(" "); KernelHex(kernel_probe_span); KernelLog("\n");
  }
}

U0 KernelFileLoad()
{
  CI386ModuleBinding bindings[18];
  if(kernel_file_image || kernel_files.version) KernelStop;
  KernelBinding(&bindings[0],"I386HeapAlloc"); KernelBinding(&bindings[1],"I386HeapFree");
  KernelBinding(&bindings[2],"I386HeapSize"); KernelBinding(&bindings[3],"I386IrqSave");
  KernelBinding(&bindings[4],"I386IrqRestore"); KernelBinding(&bindings[5],"I386RedSeaFind");
  KernelBinding(&bindings[6],"I386RedSeaResolve"); KernelBinding(&bindings[7],"I386RedSeaReadAll");
  KernelBinding(&bindings[8],"I386LexIncludeTake");
  KernelBinding(&bindings[9],"I386RedSeaBegin");
  KernelBinding(&bindings[10],"I386RedSeaEnd");
  KernelBinding(&bindings[11],"I386RedSeaValid");
  KernelBinding(&bindings[12],"I386AtaIdentifyPolled");
  KernelBinding(&bindings[13],"I386AtaTransfer");
  KernelBinding(&bindings[14],"I386AtaFlushPolled");
  KernelBinding(&bindings[15],"I386SchedBlock");
  KernelBinding(&bindings[16],"I386SchedWake");
  KernelBinding(&bindings[17],"I386SchedYield");
  kernel_file_image=KernelServiceLoad("/Modules/I386/FileRuntime.t32m","FILES ",
    bindings,18,&kernel_files,sizeof(CI386FileServices),I386_FILE_SERVICES_VERSION);
  kernel_file_size=I386HeapSize(&kernel_heap,kernel_file_image);
  kernel_paths.cur_dir="/"; kernel_paths.home_dir="C:/";
  kernel_paths.cur_drv='C'; kernel_paths.boot_drv='C'; kernel_paths.white_space=char_bmp_white_space;
  kernel_volumes.letter['C'-'A']=&kernel_volume;
  kernel_file_context.paths=&kernel_paths; kernel_file_context.volumes=&kernel_volumes;
  kernel_file_include.context=&kernel_file_context; kernel_file_include.push=kernel_files.include;
}

U8 *KernelServiceLoad(U8 *path,U8 *label,CI386ModuleBinding *bindings,I64 count,
  U8 *record,I64 bytes,U32 version)
{//Private bounded service tables. Validate a stack candidate before publication.
  CI386RedSeaEntry file;
  U8 candidate[128],*image=0,*reason="load";
  I64 (*entry)(U8 *services,I64 bytes);
  I64 i,used=kernel_heap.used,allocations=kernel_heap.allocations,size=0,accepted=0;
  if(bytes<8 || bytes>sizeof(candidate) || bytes&3) KernelStop;
  for(i=0;i<bytes;i++) candidate[i]=0;
  if(I386RedSeaResolve(&kernel_volume,kernel_volume.root,path,&file)!=1) KernelStop;
  image=I386RedSeaLoadBound(&kernel_volume,&file,&kernel_heap,"Main",bindings,count);
  if(image) {
    reason="api"; size=I386HeapSize(&kernel_heap,image);
    if((image+0)(U64)>=0x110000 && size>8 && kernel_heap.allocations==allocations+1) {
      entry=image; accepted=(*entry)(candidate,bytes);
      if(!KernelServiceCheck(image,size,candidate,bytes,version)) accepted=0;
    }
  }
  if(accepted!=1) {
    if(image && !I386HeapFree(&kernel_heap,image)) KernelStop;
    if(kernel_heap.used!=used || kernel_heap.allocations!=allocations || !I386HeapValid(&kernel_heap)) KernelStop;
    KernelLog(label); KernelLog("REJECT "); KernelLog(reason); KernelLog(" reclaimed\n"); KernelStop;
  }
  for(i=0;i<bytes;i++) record[i]=candidate[i];
  KernelServiceLog(label,image,size,kernel_heap.used-used,record,bytes);
  return image;
}

Bool KernelServiceCheck(U8 *image,I64 size,U8 *record,I64 bytes,U32 version)
{//Both native service records have a version/byte header followed by four-byte pointers.
  U32 *fields=record;
  U64 base=(image+0)(U64),address;
  I64 i;
  if(bytes<8 || bytes&3 || fields[0]!=version || fields[1]!=bytes) return FALSE;
  for(i=2;i<bytes/4;i++) {
    address=fields[i];
    if(address<base+8 || address>=base+size) return FALSE;
  }
  return TRUE;
}

U0 KernelServiceLog(U8 *label,U8 *image,I64 size,I64 span,U8 *record,I64 bytes)
{
  U32 *fields=record;
  I64 i;
  KernelLog(label); KernelHex((image+0)(U64)); KernelLog(" "); KernelHex(size);
  KernelLog(" "); KernelHex(span);
  for(i=2;i<bytes/4;i++) { KernelLog(" "); KernelHex(fields[i]); }
  KernelLog("\n");
}
