//Loaded on first native build. The kernel retains code for task cleanup callbacks.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/BuildRuntime.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/ExceptRuntime.HH"
import U0 KernelLog(U8 *text);
import U0 KernelHex(I64 value);
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import Bool I386SchedYield(CI386Scheduler *scheduler);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import I64 I386RedSeaFind(CI386RedSea *volume,I64 directory,U8 *name,CI386RedSeaEntry *entry);
import I64 I386RedSeaResolve(CI386RedSea *volume,I64 directory,U8 *path,CI386RedSeaEntry *entry);
import Bool I386RedSeaBegin(CI386RedSea *volume);
import Bool I386RedSeaEnd(CI386RedSea *volume);
import Bool I386RedSeaValid(CI386RedSea *volume);
import Bool I386RedSeaDecode(CI386RedSea *volume,U8 *raw,CI386RedSeaEntry *entry);
import Bool I386RedSeaSectorRead(CI386RedSea *volume,I64 block,U8 *buffer);
import Bool I386RedSeaSectorWrite(CI386RedSea *volume,I64 block,U8 *buffer);
import Bool I386RedSeaFlush(CI386RedSea *volume);
import I64 I386RedSeaAlloc(CI386RedSea *volume,I64 count);
import Bool I386RedSeaFree(CI386RedSea *volume,I64 block,I64 count);
import I64 I386RedSeaAllocOwned(CI386RedSea *volume,I64 count,I64 *owned_block);
import Bool I386RedSeaReleaseOwned(CI386RedSea *volume,I64 block,I64 count);
import I64 I386RedSeaRead(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
import Bool I386RedSeaMount(CI386RedSea *volume,CI386Ata *disk,I64 start);
import I64 I386RedSeaWrite(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
import Bool I386RedSeaDirectory(CI386RedSea *volume,I64 block,U8 *sector,I64 *size);
import U0 I386RedSeaPutWord(U8 *p,U64 value);
import CI386TaskFiles *I386TaskFilesValid(CI386Task *task);
import Bool I386TaskFilesAccess(CI386Task *task);
#include "/Kernel/I386/TaskModuleStage.HC"
#define I386_REDSEA_MUTATION_IMPORTS 1
#include "/Kernel/I386/TaskModulePublication.HC"
#include "/Kernel/I386/BuildModule.HC"
U32 build_runtime_version=I386_BUILD_SERVICES_VERSION;
#assert sizeof(CI386BuildServices)==24
I64 Main(CI386BuildServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386BuildServices))return 0;
  services->version=build_runtime_version;services->bytes=sizeof(CI386BuildServices);
  services->stage_new=&I386TaskModuleStageNew;
  services->stage_cleanup=&I386TaskModuleStageCleanup;
  services->publish=&I386TaskModulePublish;
  services->build=&I386BuildModuleCore;
  return 1;
}
