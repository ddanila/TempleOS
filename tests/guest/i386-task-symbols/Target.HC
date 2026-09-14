#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/TaskSymbols.HH"
#include "/Compiler/I386/SymbolDelete.HH"
#include "/Kernel/I386/TaskFiles.HH"
#include "/Kernel/I386/TaskCompiler.HH"
#include "/Kernel/CharBitmaps.HC"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Ports.HH"
#include "/Kernel/I386/Irq.HH"
extern Bool I386DataSegment(U8 *descriptor,U8 *base,I64 size);
class CDispatch { U0 (*handler)(CI386IrqFrame *frame); };
class CControl {
  CDispatch *irq; U0 (*idle)(); I64 (*segments)(I64 callback);
  U0 (*reload)(U16 fs,U16 gs); U8 *task_descriptor,*cpu_descriptor;
};
CControl *control;
CI386Scheduler scheduler;
CI386Task root;
CI386Cpu cpu;
CI386Heap heap;
CI386OwnedTask *workers[2],*grand;
CHashTable *symbols;
CHashDefineStr root_symbol;
CFilePathContext paths;
CI386FileVolumes volumes;
U32 white_space[8],errors,scope_done,protected_parent;
CI386CompilerServices control_services;
CI386TaskCompilerConfig task_compiler,other_compiler;
CCmpCtrl *retained_control;
extern I64 FactoryRootTest();
extern I64 ActiveTest();
extern I64 UnwindRootTest();
extern I64 CodeTest();
extern I64 CodeViewsTest();
extern I64 CodeRetireTest();
extern Bool FactoryWorkerTest(I64 id);
U0 (*swap)(CI386Context *old,CI386Context *next);
extern I64 ScopeTest();
extern U0 Worker(I64 id);
extern U0 Grandchild(I64 unused);
U0 Bind(CI386Task *task)
{
  if((GetRFlags&0x200) || !I386DataSegment(control->task_descriptor,task,sizeof(CI386Task))) errors++;
  (*control->reload)(0x18,0x20);
}
I64 Main(I64 a,I64 b)
{
  control=a; swap=b;
  return (*control->segments)(&ScopeTest);
}
I64 ScopeTest()
{
  I64 i,round,used,allocations;
  CI386TaskFiles *borrow;
  CFilePathContext snapshot;
  CI386FileVolumes *selected;
  cpu.addr=&cpu; cpu.scheduler=&scheduler;
  if(!I386SchedInit(&scheduler,&root,swap) ||
      !I386DataSegment(control->cpu_descriptor,&cpu,sizeof(CI386Cpu)) ||
      !I386SchedSetBind(&scheduler,&Bind) || !I386HeapInit(&heap,0x60000,65536)) return 1;
  OutU8(0x21,255); OutU8(0xA1,255);
  symbols=I386HashTableNew(&heap,8);
  if(!symbols || !I386TaskSymbolsInit(&root,&heap,symbols) ||
      I386TaskSymbolsInit(&root,&heap,symbols)) return 2;
  root_symbol.str="Shared"; root_symbol.type=HTT_DEFINE_STR; root_symbol.data="root";
  HashAdd(&root_symbol,symbols);
  paths.cur_dir="/"; paths.home_dir="C:/"; paths.cur_drv='C'; paths.boot_drv='C'; paths.white_space=white_space;
  if(!I386TaskFilesInit(&root,&heap,&paths,&volumes)) return 3;
  i=FactoryRootTest; if(i) return i;
  used=heap.used; allocations=heap.allocations;
  for(i=24;i<=512;i+=8)
    if(I386TaskSpawn(&scheduler,&heap,4096,&Worker,0,0x18,0x20,i) ||
        heap.used!=used || heap.allocations!=allocations || root.lifetime_refs || root.next!=&root) return 4;
  root.lifetime_refs=0xFFFFFFFF;
  if(I386TaskSpawn(&scheduler,&heap,4096,&Worker,0,0x18,0x20,8192) ||
      heap.used!=used || heap.allocations!=allocations) return 5;
  root.lifetime_refs=0;
  for(i=0;i<2;i++) {
    workers[i]=I386TaskSpawn(&scheduler,&heap,4096,&Worker,i,0x18,0x20,8192);
    if(!workers[i] || workers[i]->task.hash_table==symbols ||
        workers[i]->task.hash_table->next!=symbols || workers[i]->task.hash_table->mask!=1023) return 6;
  }
  for(round=0;round<100;round++) {
    I386SchedYield(&scheduler);
    if(grand && workers[0]->task.finished && workers[0]->task.lifetime_refs) {
      if(I386TaskDestroy(workers[0]) || !workers[0]->task.file_state || !workers[0]->task.hash_table) return 7;
      protected_parent++;
    }
    if(grand && grand->task.finished && workers[0]->task.finished && workers[1]->task.finished) break;
  }
  if(errors || scope_done!=3 || !protected_parent || root.lifetime_refs!=2 ||
      HashFind("Shared",symbols,HTT_DEFINE_STR)!=&root_symbol) return 8;
  if(!I386TaskDestroy(grand) || workers[0]->task.lifetime_refs!=1 || I386TaskDestroy(workers[0]) ||
      !I386CmpCtrlDel(workers[0]->task.memory,retained_control) ||
      !I386TaskDestroy(workers[0]) || !I386TaskDestroy(workers[1]) ||
      root.lifetime_refs || heap.used!=used || heap.allocations!=allocations) return 9;
  i=ActiveTest; if(i) return i;
  i=UnwindRootTest; if(i) return i;
  i=CodeTest; if(i) return i;
  i=CodeViewsTest; if(i) return i;
  i=CodeRetireTest; if(i) return i;
  borrow=I386TaskFilesBorrow(&root,&snapshot,&selected);
  if(!borrow || I386TaskSymbolsDestroy(&root) || !I386TaskFilesRelease(borrow) ||
      !I386TaskSymbolsDestroy(&root) || !I386TaskFilesDestroy(&root) ||
      HashFind("Shared",symbols,HTT_DEFINE_STR)!=&root_symbol ||
      !I386HashTableRemove(&heap,symbols,&root_symbol) || !I386HashTableDelete(&heap,symbols) ||
      heap.used || heap.allocations || !I386HeapValid(&heap)) return 10;
  return 0;
}
Bool Define(U8 value)
{
  CI386TaskSymbols *state=I386TaskSelf->symbol_state;
  CHashDefineStr *entry;
  U8 *name,*data;
  I64 i;
  entry=I386HeapAlloc(state->heap,sizeof(CHashDefineStr),TRUE);
  name=I386HeapAlloc(state->heap,7,FALSE); data=I386HeapAlloc(state->heap,2,TRUE);
  if(!entry || !name || !data) return FALSE;
  for(i=0;i<7;i++) name[i]="Shared"(U8 *)[i];
  data[0]=value; entry->str=name; entry->data=data; entry->type=HTT_DEFINE_STR;
  HashAdd(entry,I386TaskSelf->hash_table);
  return HashFind("Shared",I386TaskSelf->hash_table,HTT_DEFINE_STR)==entry;
}
U0 Worker(I64 id)
{
  if(HashFind("Shared",I386TaskSelf->hash_table,HTT_DEFINE_STR)!=&root_symbol || !Define('A'+id)) { errors++; return; }
  if(!FactoryWorkerTest(id)) { errors++; return; }
  if(!id) {
    grand=I386TaskSpawn(&scheduler,&heap,4096,&Grandchild,0);
    if(!grand || grand->task.hash_table->next!=I386TaskSelf->hash_table) { errors++; return; }
  }
  scope_done++;
}
U0 Grandchild(I64 unused)
{
  CHashDefineStr *entry=HashFind("Shared",I386TaskSelf->hash_table,HTT_DEFINE_STR);
  if(!entry || entry==&root_symbol || entry->data[0]!='A' || !workers[0]->task.finished ||
      I386TaskSelf->memory || !Define('G')) { errors++; return; }
  I386SchedYield(&scheduler);
  entry=HashFind("Shared",I386TaskSelf->hash_table,HTT_DEFINE_STR);
  if(!entry || entry->data[0]!='G' || workers[0]->task.lifetime_refs!=2) errors++;
  scope_done++;
}
#include "/Kernel/I386/Context.HC"
#include "/Kernel/I386/Cpu.HC"
#include "/Kernel/I386/Heap.HC"
#include "/Kernel/I386/Scheduler.HC"
#include "/Kernel/I386/Task.HC"
#include "/Kernel/I386/Segments.HC"
#include "/Kernel/I386/Hash.HC"
#include "/Kernel/I386/HashTable.HC"
#include "/Compiler/I386/SymbolDelete.HC"
#include "/Kernel/I386/TaskSymbols.HC"
#include "/Kernel/I386/TaskFiles.HC"

#include "/Compiler/ControlInit.HC"
#include "/Compiler/I386/LexFiles.HC"
#include "/Compiler/I386/Control.HC"
#include "/Kernel/BlkDev/FileNames.HC"
#include "/Kernel/I386/FilePaths.HC"
#include "/Kernel/I386/TaskCompiler.HC"
#include "T:/Factory.HC"

#include "T:/Active.HC"

#include "T:/Unwind.HC"

#include "T:/Code.HC"

#include "T:/Views.HC"

#include "T:/Retire.HC"
