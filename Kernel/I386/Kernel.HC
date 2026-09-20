//Native kernel foundation with a retained compiler and source-driven HolyC console.
#include "/Kernel/Types.HH"

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
#include "/Kernel/I386/ConsoleRuntime.HH"
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
#include "/Kernel/I386/MemoryRuntime.HH"
#include "/Kernel/I386/KernelSymbols.HH"
import U0 i386_idle();
U8 *kernel_ready_message="READY native kernel foundation\n";
CI386Scheduler kernel_scheduler;
CI386Task kernel_root;
CI386Cpu kernel_cpu;
CI386Heap kernel_heap;
CI386Ata kernel_disk;
CI386RedSea kernel_volume;
CI386Timer kernel_timer;
CI386SleepQueue kernel_sleep;
CI386ConsoleServices kernel_console;
CI386ConsoleConfig kernel_console_config;
U8 *kernel_console_image;
//Build tooling enables this data flag only in the diagnostic disk copy.
U32 kernel_diagnostics=0;
Bool kernel_display_ready,kernel_probe_ready;
CI386KbcInput kernel_input;
CI386KeyboardReader kernel_reader;
U8 kernel_gdt[40],kernel_idt[2048];

CI386OwnedTask *kernel_pulse;
CI386OwnedTask *kernel_keys;
I64 kernel_startup_count;
CHashTable *kernel_symbols;
CHashClass *kernel_scalars[6];
CI386InternalTypes kernel_types;
CI386Keywords kernel_keywords;
CI386KernelSymbol kernel_exports[45];
U8 kernel_export_kinds[45]={1,1,3,1,1,3,3,3,1,1,1,1,1,1,1,1,1,3,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
CI386CompilerServices kernel_compiler;
CI386FileServices kernel_files;
CI386MemoryServices kernel_memory;
U8 *kernel_memory_image;
U8 *kernel_file_image;
I64 kernel_file_size;
CFilePathContext kernel_paths;
CI386FileVolumes kernel_volumes;
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
extern U0 KernelMemoryLoad();
extern U8 *KernelServiceLoad(U8 *path,U8 *label,CI386ModuleBinding *bindings,I64 count,
  U8 *record,I64 bytes,U32 version);
extern Bool KernelServiceCheck(U8 *image,I64 size,U8 *record,I64 bytes,U32 version);
extern U0 KernelServiceLog(U8 *label,U8 *image,I64 size,I64 span,U8 *record,I64 bytes);
extern U0 KernelCompilerProbe(I64 phase);
extern U0 KernelConsoleLoad();
extern U0 KernelSymbols();
U8 kernel_startup_bindings[3]={0,1,2};
U8 kernel_compiler_bindings[23]={3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,35,36,37,38,39,42,40,41};
U8 kernel_probe_bindings[22]={0,18,19,12,11,20,13,14,3,15,16,9,21,40,41,42,10,43,44,34,25,35};
U8 kernel_files_bindings[18]={10,11,12,13,14,22,23,24,25,26,27,28,29,30,31,32,33,34};
U8 kernel_memory_bindings[11]={10,11,12,20,13,14,0,18,19,16,42};
extern U0 KernelBinding(CI386ModuleBinding *binding,U8 *name);
extern U0 KernelBindings(CI386ModuleBinding *bindings,U8 *indices,I64 count,I64 capacity);
I64 Main(CI386BootInfo *info,I64 unused)
{
  CI386MemRange reserved,arena;
  CI386InterruptServices services;
  I64 pulse_used;
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
  KernelMemoryLoad;
  if(kernel_diagnostics) KernelCompilerProbe(0);
  if(!kernel_compiler.load_scalar_types(&kernel_heap,kernel_types.by_raw,&kernel_files,&kernel_file_include,kernel_scalars)) KernelStop;
  KernelConsoleLoad;
  KernelStartup;
  if(!kernel_files.bind(&kernel_scheduler,&kernel_volume)) KernelStop;
  KernelLog("STORAGE TASK BOUND\n");
  if(!I386KbcInputInit(&kernel_input,&kernel_scheduler) ||
      !I386KeyboardReadInit(&kernel_reader,&kernel_input) || !I386KeyboardSetup) KernelStop;
  KernelLog(kernel_ready_message);
  I386PicMask(0xFFFC);
  if(kernel_diagnostics) {
    kernel_pulse=I386TaskSpawn(&kernel_scheduler,&kernel_heap,16384,&KernelPulse,0,
      0x18,0x20,524288);
    if(!kernel_pulse) KernelStop;
    //This diagnostic compiler arena is released with the worker after its probes.
    //Complete public headers and retained functions exceed the former 128 KiB.
    //The full bit-assignment corpus needs more than the former 8 KiB stack;
    //retain the parser's 4 KiB reserve and provide 16 KiB for this worker.
    //Finish heap-accounting diagnostics before accepting interactive allocations.
    while(!kernel_probe_ready) {
      if(!I386SchedIdle(&kernel_scheduler,&i386_idle)) I386SchedYield(&kernel_scheduler);
    }
    pulse_used=kernel_heap.used;
    if(!kernel_pulse->task.finished || !I386TaskDestroy(kernel_pulse) ||
        pulse_used-kernel_heap.used<524288+16384) KernelStop;
    kernel_pulse=0;
    KernelLog("PROBE TASK RELEASE "); KernelHex(pulse_used-kernel_heap.used); KernelLog("\n");
  }
  kernel_keys=I386TaskSpawn(&kernel_scheduler,&kernel_heap,65536,kernel_console.keys,0,
    0x18,0x20,0);
  if(!kernel_keys) KernelStop;
  kernel_keys->task.memory=&kernel_heap;
  KernelLog("CONSOLE TASK SPAWNED\n");
  while(1) {
    if(!I386SchedIdle(&kernel_scheduler,&i386_idle)) I386SchedYield(&kernel_scheduler);
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
  I64 pulses;
  for(pulses=0;pulses<2;pulses++) {
    if(!I386SleepTicks(&kernel_sleep,25)) KernelStop;
    KernelLog("TICK "); KernelHex(I386TimerTicks(&kernel_timer)); KernelLog("\n");
  }
  kernel_memory.probe(1);
  KernelCompilerProbe(1);
  if(!kernel_compiler.scalar_types_check(kernel_scalars,FALSE)) KernelStop;
  kernel_probe_ready=TRUE;
  KernelLog("SCALAR LIVE 0000000000000001\n");
}
U0 KernelDisplay()
{
  if(!kernel_console.display()) KernelStop;
  kernel_display_ready=TRUE;
}
#include "/Kernel/I386/BootMemory.HC"
#include "/Kernel/I386/A20.HC"
#include "/Kernel/I386/ModuleFileSingle.HC"
#include "/Kernel/I386/Frame.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Except.HC"
#include "/Kernel/I386/ExceptRuntime.HC"
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/SchedulerCore.HC"
#include "/Kernel/I386/TaskLifetime.HC"
#include "/Kernel/I386/Segments.HC"
#include "/Kernel/I386/Gdt.HC"
#include "/Kernel/I386/TaskPlatform.HC"
#include "/Kernel/I386/ExceptNative.HC"
#include "/Kernel/I386/Idt.HC"
#include "/Kernel/I386/Interrupt.HC"
#include "/Kernel/I386/PicPit.HC"
#include "/Kernel/I386/Timer.HC"
#include "/Kernel/I386/Sleep.HC"


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
#include "/Kernel/I386/HashTableCore.HC"
#include "/Kernel/HashValue.HC"
#include "/Compiler/I386/SymbolAlloc.HC"
#include "/Compiler/I386/SymbolDelete.HC"
#include "/Compiler/I386/InternalTypes.HC"
#include "/Compiler/I386/Keywords.HC"
#include "/Kernel/CharBitmaps.HC"
#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/LexInput.HC"


U0 KernelStorage(CI386BootInfo *info)
{//Initial profile: BIOS drive 0x80 is primary IDE master; boot I/O owns the channel.
  CI386BootDiskInfo *boot=I386_BOOT_DISK_INFO_ADDRESS;
  if(boot->magic!=I386_BOOT_DISK_INFO_MAGIC || boot->version!=1 ||
      boot->bios_drive!=0x80 || boot->volume_start<=(info->stage_end-info->stage_begin)/512 ||
      !I386AtaIdentify(&kernel_disk,0,0) ||
      !I386RedSeaMount(&kernel_volume,&kernel_disk,boot->volume_start)) KernelStop;
  KernelLog("REDSEA "); KernelHex(kernel_volume.start); KernelLog(" ");
  KernelHex(kernel_volume.sectors); KernelLog("\n");
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
  KernelBindings(bindings,kernel_startup_bindings,3,sizeof(bindings)/sizeof(CI386ModuleBinding));
  image=I386RedSeaLoadBound(&kernel_volume,&file,&kernel_heap,"Main",bindings,3);
  if(!image || kernel_heap.allocations!=allocations+1) KernelStop;
  transient=kernel_heap.used-used;
  entry=image;
  result=(*entry)();
  after=kernel_heap.used; allocations=kernel_heap.allocations;
  if(result!=1 || kernel_startup_count!=1 || !kernel_display_ready || transient<=0 ||
      !I386HeapFree(&kernel_heap,image) || kernel_heap.used!=after-transient ||
      kernel_heap.allocations!=allocations-1 || !I386HeapValid(&kernel_heap)) KernelStop;
  KernelLog("MODULE "); KernelHex(result); KernelLog(" ");
  KernelHex(transient); KernelLog("\n");
}

U0 KernelSymbols()
{//Boot-only private export index, using the shared public hash-record prefix.
//These records describe loader bindings; they are not compiler CHashFun objects.
  I64 i,used;
  U8 *addresses[45],*names="KernelLog\0KernelDisplay\0kernel_startup_count\0I386LexRawChar\0I386LexSourceRead\0char_bmp_hex_numeric\0char_bmp_dec_numeric\0char_bmp_non_eol\0HashFind\0StrCmp\0I386HeapAlloc\0I386HeapFree\0I386HeapSize\0I386IrqSave\0I386IrqRestore\0I386LexIncludeCopy\0HashAdd\0char_bmp_non_eol_white_space\0KernelHex\0KernelStop\0I386HeapValid\0char_bmp_alpha_numeric\0I386RedSeaFind\0I386RedSeaResolve\0I386RedSeaReadAll\0I386LexIncludeTake\0I386RedSeaBegin\0I386RedSeaEnd\0I386RedSeaValid\0I386AtaIdentifyPolled\0I386AtaTransfer\0I386AtaFlushPolled\0I386SchedBlock\0I386SchedWake\0I386SchedYield\0I386LexFilePush\0LexFileReleaseTop\0I386HashTableNew\0I386HashTableValid\0I386HashTableDelete\0SysTry\0SysUntry\0throw\0I386TaskSpawn\0I386TaskDestroy\0";
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
  addresses[35]=&I386LexFilePush; addresses[36]=&LexFileReleaseTop;
  addresses[37]=&I386HashTableNew; addresses[38]=&I386HashTableValid; addresses[39]=&I386HashTableDelete;
  addresses[40]=&SysTry; addresses[41]=&SysUntry; addresses[42]=&throw;
  addresses[43]=&I386TaskSpawn; addresses[44]=&I386TaskDestroy;
  for(i=0;i<45;i++) {
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

U0 KernelBindings(CI386ModuleBinding *bindings,U8 *indices,I64 count,I64 capacity)
{
  I64 i;
  if(!bindings || !indices || count!=capacity || count<1 || count>45) KernelStop;
  for(i=0;i<count;i++) {
    if(indices[i]>=45) KernelStop;
    KernelBinding(&bindings[i],kernel_exports[indices[i]].str);
  }
}

U0 KernelCompilerLoad()
{//Boot owns ATA/heap with IF clear. Publish only a validated, retained interface.
  CI386ModuleBinding bindings[sizeof(kernel_compiler_bindings)];
  I64 used=kernel_heap.used;
  if(kernel_compiler_image || kernel_compiler.version) KernelStop;
  KernelBindings(bindings,kernel_compiler_bindings,sizeof(kernel_compiler_bindings),sizeof(bindings)/sizeof(CI386ModuleBinding));
  kernel_compiler_image=KernelServiceLoad("/Modules/I386/CompilerRuntime.t32m","RUNTIME ",
    bindings,sizeof(kernel_compiler_bindings),&kernel_compiler,sizeof(CI386CompilerServices),I386_COMPILER_SERVICES_VERSION);
  kernel_compiler_size=I386HeapSize(&kernel_heap,kernel_compiler_image);
  kernel_compiler_span=kernel_heap.used-used;
  if(!kernel_compiler.symbols_init(&kernel_root,&kernel_heap,kernel_symbols,1024)) KernelStop;
}
U0 KernelCompilerProbe(I64 phase)
{//Load once with boot disk ownership; the task call performs no disk I/O.
  CI386RedSeaEntry file; CI386ModuleBinding bindings[sizeof(kernel_probe_bindings)]; CI386CompilerProbe probe;
  I64 (*entry)(CI386CompilerProbe *probe,I64 bytes);
  I64 used=kernel_heap.used,allocations=kernel_heap.allocations;
  U32 flags;
  if(phase==0) {
    if(kernel_probe_image) KernelStop;
    KernelBindings(bindings,kernel_probe_bindings,sizeof(kernel_probe_bindings),sizeof(bindings)/sizeof(CI386ModuleBinding));
    if(I386RedSeaFind(&kernel_volume,kernel_volume.root,"Modules",&file)!=1 ||
        !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"I386",&file)!=1 ||
        !(file.attr&0x10) || I386RedSeaFind(&kernel_volume,file.block,"CompilerProbe.t32m",&file)!=1) KernelStop;
    kernel_probe_image=I386RedSeaLoadBound(&kernel_volume,&file,&kernel_heap,"Main",bindings,sizeof(kernel_probe_bindings));
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
  probe.internal_types=kernel_types.by_raw;
  probe.i64_type=kernel_types.by_raw[RT_I64]; probe.runtime_image=kernel_compiler_image;
  probe.runtime_size=kernel_compiler_size; probe.phase=phase;
  probe.disk_include=&kernel_file_include; probe.files=&kernel_files;
  probe.volume=&kernel_volume; probe.source_read=&I386RedSeaFileRead;
  probe.source_pop=&I386LexFilePop;
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
  KernelBindings(bindings,kernel_files_bindings,18,sizeof(bindings)/sizeof(CI386ModuleBinding));
  kernel_file_image=KernelServiceLoad("/Modules/I386/FileRuntime.t32m","FILES ",
    bindings,18,&kernel_files,sizeof(CI386FileServices),I386_FILE_SERVICES_VERSION);
  kernel_file_size=I386HeapSize(&kernel_heap,kernel_file_image);
  kernel_paths.cur_dir="/"; kernel_paths.home_dir="C:/";
  kernel_paths.cur_drv='C'; kernel_paths.boot_drv='C'; kernel_paths.white_space=char_bmp_white_space;
  kernel_volumes.letter['C'-'A']=&kernel_volume;
  if(!kernel_files.init(&kernel_root,&kernel_heap,&kernel_paths,&kernel_volumes)) KernelStop;
  if(!kernel_files.compiler_init(&kernel_compiler,"~/Tmp.DD.Z",char_bmp_alpha_numeric,char_bmp_alpha_numeric_no_at)) KernelStop;
  kernel_file_include.context=0; kernel_file_include.push=kernel_files.include;
  kernel_file_include.directive_context=0; kernel_file_include.directive=0;
}

U0 KernelMemoryLoad()
{
  CI386ModuleBinding bindings[sizeof(kernel_memory_bindings)];
  if(kernel_memory_image || kernel_memory.version) KernelStop;
  KernelBindings(bindings,kernel_memory_bindings,sizeof(kernel_memory_bindings),sizeof(bindings)/sizeof(CI386ModuleBinding));
  kernel_memory_image=KernelServiceLoad("/Modules/I386/MemoryRuntime.t32m","MEMORY ",
    bindings,sizeof(kernel_memory_bindings),&kernel_memory,sizeof(CI386MemoryServices),I386_MEMORY_SERVICES_VERSION);
  if(!kernel_memory.bind(&kernel_root,&kernel_heap,kernel_symbols)) KernelStop;
  if(kernel_diagnostics) kernel_memory.probe(0);
}

U8 *KernelServiceLoad(U8 *path,U8 *label,CI386ModuleBinding *bindings,I64 count,
  U8 *record,I64 bytes,U32 version)
{//Private bounded service tables. Validate a stack candidate before publication.
  CI386RedSeaEntry file;
  U8 candidate[sizeof(CI386CompilerServices)],*image=0,*reason="load";
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

U0 KernelConsoleLoad()
{
  CI386ModuleBinding bindings[6];
  U8 indices[6];
  indices[0]=0; indices[1]=19; indices[2]=10; indices[3]=40; indices[4]=41; indices[5]=18;
  KernelBindings(bindings,indices,6,6);
  kernel_console_image=KernelServiceLoad("/Modules/I386/ConsoleRuntime.t32m","CONSOLE ",
    bindings,6,&kernel_console,sizeof(CI386ConsoleServices),I386_CONSOLE_VERSION);
  kernel_console_config.heap=&kernel_heap; kernel_console_config.compiler=&kernel_compiler;
  kernel_console_config.files=&kernel_files; kernel_console_config.includes=&kernel_file_include;
  kernel_console_config.types=kernel_types.by_raw; kernel_console_config.reader=&kernel_reader;
  kernel_console_config.read=&I386KeyboardRead;
  if(!kernel_console.init(&kernel_console_config)) KernelStop;
}
