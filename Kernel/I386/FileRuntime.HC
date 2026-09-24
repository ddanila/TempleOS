//Retained current-task file services. Code and borrowed configuration have kernel lifetime.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/FileRuntime.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/RedSeaTask.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import I64 I386RedSeaFind(CI386RedSea *volume,I64 directory,U8 *name,CI386RedSeaEntry *entry);
import I64 I386RedSeaResolve(CI386RedSea *volume,I64 directory,U8 *path,CI386RedSeaEntry *entry);
import U8 *I386RedSeaReadAll(CI386RedSea *volume,CI386Heap *heap,CI386RedSeaEntry *entry,I64 *size=0);
import Bool I386LexIncludeTake(CI386Heap *heap,CCmpCtrl *cc,U8 *name,U8 *source,Bool is_define=FALSE);
import Bool I386RedSeaBegin(CI386RedSea *volume);
import Bool I386RedSeaEnd(CI386RedSea *volume);
import Bool I386RedSeaValid(CI386RedSea *volume);
import Bool I386AtaIdentifyPolled(CI386Ata *disk,I64 channel,I64 drive,I64 polls,CI386AtaPoll *poll);
import Bool I386AtaTransfer(CI386Ata *disk,I64 lba,U8 *buffer,I64 polls,Bool write,CI386AtaPoll *poll);
import Bool I386AtaFlushPolled(CI386Ata *disk,I64 polls,CI386AtaPoll *poll);
import Bool I386SchedBlock(CI386Scheduler *scheduler);
import Bool I386SchedWake(CI386Scheduler *scheduler,CI386Task *task);
import Bool I386SchedYield(CI386Scheduler *scheduler);
extern Bool I386TaskFileWrite(U8 *filename,U8 *buffer,I64 size,I64 attr=0);
extern Bool I386TaskDirMk(U8 *filename,I64 entry_cnt=0);
extern I64 I386TaskDirList(U8 *filename,U8 *buffer,I64 capacity,I64 *entries=0);
extern Bool I386TaskFileDelete(U8 *filename);
extern Bool I386TaskFileRename(U8 *old_filename,U8 *new_filename);
extern Bool I386TaskDirDelete(U8 *filename);
extern Bool I386TaskFileMove(U8 *old_filename,U8 *new_filename);
extern Bool I386TaskFileMoveProbe();
extern Bool I386TaskFileMoveIoProbe(I64 operation,I64 fail_after);
import Bool I386RedSeaSectorRead(CI386RedSea *volume,I64 block,U8 *buffer);
import Bool I386RedSeaSectorWrite(CI386RedSea *volume,I64 block,U8 *buffer);
import Bool I386RedSeaFlush(CI386RedSea *volume);
import I64 I386RedSeaAlloc(CI386RedSea *volume,I64 count);
import Bool I386RedSeaFree(CI386RedSea *volume,I64 block,I64 count);
import Bool I386RedSeaMoveIntentSet(CI386RedSea *volume,I64 source_parent,Bool source_root,
  U8 *source_name,I64 destination_parent,Bool destination_root,U8 *destination_name,
  CI386RedSeaEntry *source);
import Bool I386RedSeaMoveIntentClear(CI386RedSea *volume);
import I64 I386RedSeaWrite(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
import Bool I386RedSeaDirectory(CI386RedSea *volume,I64 block,U8 *sector,I64 *size);
import U0 I386RedSeaPutWord(U8 *p,U64 value);
import U0 KernelLog(U8 *text);
CI386AtaChannel file_channels[2];
CI386RedSeaIo file_io[2];
Bool I386FileRuntimeCancelWait(CI386Task *task)
{
  I64 i;
  for(i=0;i<2;i++) if(I386AtaChannelCancelWait(&file_channels[i],task)) return TRUE;
  return FALSE;
}
Bool I386FileRuntimeBind(CI386Scheduler *scheduler,CI386RedSea *volume)
{
  I64 number;
  if(GetRFlags&0x200 || !scheduler || scheduler->current!=scheduler->root ||
      !I386RedSeaValid(volume) || volume->io) return FALSE;
  number=0;
  if(volume->disk->io==0x170) number=1;
  else if(volume->disk->io!=0x1F0) return FALSE;
  if(!file_channels[number].signature) {
    if(!I386AtaChannelInit(&file_channels[number],scheduler,number) ||
        !I386RedSeaTaskIoInit(&file_io[number],&file_channels[number])) return FALSE;
  }
  if(file_channels[number].scheduler!=scheduler) return FALSE;
  return I386RedSeaTaskBind(volume,&file_io[number]);
}
CI386TaskCompilerConfig file_compiler;
Bool I386FileRuntimeCompiler(CI386CompilerServices *compiler,U8 *tmp_filename,U32 *alpha_numeric,U32 *alpha_numeric_no_at)
{
  return I386TaskCompilerInit(&file_compiler,compiler,tmp_filename,alpha_numeric,alpha_numeric_no_at);
}
CCmpCtrl *I386FileRuntimeControl(U8 *buffer,I64 flags,U8 *filename)
{
  return I386TaskCmpCtrlNew(&file_compiler,buffer,flags,filename);
}
U32 file_runtime_version=I386_FILE_SERVICES_VERSION;
#assert sizeof(CI386FileServices)==76
I64 Main(CI386FileServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386FileServices)) return 0;
  services->version=file_runtime_version; services->bytes=sizeof(CI386FileServices);
  services->include=&I386LexTaskFileInclude; services->read=&I386TaskFileRead;
  services->name_abs=&I386TaskFileNameAbs;
  services->bind=&I386FileRuntimeBind; services->init=&I386TaskFilesInit;
  services->compiler_init=&I386FileRuntimeCompiler; services->control_new=&I386FileRuntimeControl;
  services->cancel_wait=&I386FileRuntimeCancelWait;
  services->write=&I386TaskFileWrite;
  services->dir_mk=&I386TaskDirMk;
  services->dir_list=&I386TaskDirList;
  services->del=&I386TaskFileDelete;
  services->rename=&I386TaskFileRename;
  services->dir_del=&I386TaskDirDelete;
  services->move=&I386TaskFileMove;
  services->move_probe=&I386TaskFileMoveProbe;
  services->move_io_probe=&I386TaskFileMoveIoProbe;
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
#include "/Kernel/I386/AtaChannel.HC"
#include "/Kernel/I386/AtaTask.HC"
#include "/Kernel/I386/RedSeaTask.HC"

#include "/Kernel/I386/TaskFiles.HC"
#include "/Kernel/I386/TaskFileRead.HC"
#define I386_REDSEA_MUTATION_IMPORTS 1
#include "/Kernel/I386/RedSeaCreate.HC"
#include "/Kernel/I386/RedSeaReplace.HC"
#include "/Kernel/I386/RedSeaDelete.HC"
#include "/Kernel/I386/RedSeaRename.HC"
#include "/Kernel/I386/RedSeaDirDelete.HC"
#include "/Kernel/I386/TaskFileWrite.HC"
#include "/Kernel/I386/TaskCompiler.HC"
