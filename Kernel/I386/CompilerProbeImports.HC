//Synchronous compiler diagnostics, retained only between boot and task probes.
#include "/Kernel/Types.HH"
#include "/Kernel/QueueTypes.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/CompilerProbe.HH"
#include "/Compiler/ControlInit.HH"
#include "/Compiler/CompilerA.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/Hash.HH"
#include "/Kernel/I386/String.HH"
#include "/Kernel/I386/ExceptRuntime.HH"
#ifdef I386_PROBE_MODULE_LOADER
#include "/Kernel/I386/ModuleLoad.HC"
#else
#include "/Kernel/I386/ModuleBind.HH"
#endif
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
import CI386OwnedTask *I386TaskSpawn(CI386Scheduler *scheduler,CI386Heap *heap,
  I64 stack_size,U0 (*entry)(I64 arg),I64 arg,U16 fs=0x18,U16 gs=0x20,I64 private_size=0);
import Bool I386RedSeaBegin(CI386RedSea *volume);
import Bool I386RedSeaEnd(CI386RedSea *volume);
import I64 I386RedSeaResolve(CI386RedSea *volume,I64 directory,U8 *path,CI386RedSeaEntry *entry);
import Bool I386TaskDestroy(CI386OwnedTask *owned);
import Bool I386SchedYield(CI386Scheduler *scheduler);
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import Bool I386HeapValid(CI386Heap *heap);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
import Bool I386LexIncludeCopy(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
import U0 HashAdd(CHash *entry,CHashTable *table);
import I64 StrCmp(U8 *left,U8 *right);
import U32 char_bmp_alpha_numeric[16];
import Bool I386LexIncludeTake(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
#include "/Compiler/I386/LexState.HH"
import Bool I386LexFileOwned(CI386Heap *heap,CCmpCtrl *cc,CLexFile *file);
import Bool I386LexFileReleaseDetached(CI386Heap *heap,CCmpCtrl *cc,CLexFile *file);
import Bool I386LexSnapshotValid(CI386Heap *heap,CCmpCtrl *cc,CI386LexSnapshot *snapshot);
import Bool I386LexSnapshotsPin(CI386Heap *heap,CCmpCtrl *cc,CLexFile *file,Bool *pinned);
import CLexFile *I386LexFilePush(CI386Heap *heap,CCmpCtrl *cc);
#include "/Kernel/I386/BackingCheck.HC"
