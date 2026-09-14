//Disk-loaded file/path/expansion services. Calls require quiescent volumes and IF clear.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/FileRuntime.HH"
#include "/Kernel/I386/Cpu.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import I64 I386RedSeaFind(CI386RedSea *volume,I64 directory,U8 *name,CI386RedSeaEntry *entry);
import I64 I386RedSeaResolve(CI386RedSea *volume,I64 directory,U8 *path,CI386RedSeaEntry *entry);
import U8 *I386RedSeaReadAll(CI386RedSea *volume,CI386Heap *heap,CI386RedSeaEntry *entry,I64 *size=0);
import Bool I386LexIncludeTake(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
U32 file_runtime_version=I386_FILE_SERVICES_VERSION;
#assert sizeof(CI386FileServices)==16
I64 Main(CI386FileServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386FileServices)) return 0;
  services->version=file_runtime_version; services->bytes=sizeof(CI386FileServices);
  services->include=&I386LexFileInclude; services->read=&I386FileReadAt;
  return 1;
}
#include "/Kernel/I386/FileNames.HC"
#include "/Kernel/I386/FilePaths.HC"
#include "/Kernel/I386/Arc.HC"
#include "/Kernel/I386/ArcExpand.HC"
#include "/Kernel/I386/Expand.HC"
#include "/Kernel/I386/FileLoad.HC"
#include "/Kernel/I386/FileContext.HC"
#include "/Compiler/I386/LexFileRead.HC"
