//Retained current-task file services. Code and borrowed configuration have kernel lifetime.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#include "/Kernel/I386/FileRuntime.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/ExceptRuntime.HH"
#include "/Kernel/I386/RedSeaTask.HH"
#include "/Kernel/I386/Arc.HH"
#include "/Kernel/I386/TaskModuleStage.HH"
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import U32 I386IrqSave();
import U0 throw(I64 ch=0,Bool no_log=FALSE);
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
extern Bool I386TaskCd(U8 *dirname,Bool make_dirs);
extern I64 I386TaskFileFind(CI386Heap *heap,U8 *filename,CDirEntry *entry,I64 flags);
extern I64 I386TaskFileWritePublic(U8 *filename,U8 *buffer,I64 size,I64 datetime,I64 attr,CI386WriteCache *cache=0);
extern Bool I386TaskFileWrite(U8 *filename,U8 *buffer,I64 size,I64 attr=0);
extern Bool I386TaskDirMk(U8 *filename,I64 entry_cnt=0);
extern I64 I386TaskDirList(U8 *filename,U8 *buffer,I64 capacity,I64 *entries=0);
extern Bool I386TaskFileDelete(U8 *filename);
extern Bool I386TaskFileRename(U8 *old_filename,U8 *new_filename);
extern Bool I386TaskDirDelete(U8 *filename);
extern Bool I386TaskFileMove(U8 *old_filename,U8 *new_filename);
extern Bool I386TaskFileMoveProbe();
extern Bool I386TaskFileMoveIoProbe(I64 operation,I64 fail_after);
extern Bool I386InstallBootArea(CI386Ata *source,CI386Ata *target);
extern Bool I386TaskInstallBoot(U8 *source,U8 *target);
extern Bool I386TaskInstallBootImage(U8 *source,U8 *target,U8 *image,I64 bytes);
import Bool I386RedSeaSectorRead(CI386RedSea *volume,I64 block,U8 *buffer);
import Bool I386RedSeaSectorWrite(CI386RedSea *volume,I64 block,U8 *buffer);
import Bool I386RedSeaFlush(CI386RedSea *volume);
import I64 I386RedSeaAlloc(CI386RedSea *volume,I64 count);
import Bool I386RedSeaFree(CI386RedSea *volume,I64 block,I64 count);
import I64 I386RedSeaAllocOwned(CI386RedSea *volume,I64 count,I64 *owned_block);
import Bool I386RedSeaReleaseOwned(CI386RedSea *volume,I64 block,I64 count);
import I64 I386RedSeaRead(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
import Bool I386RedSeaMount(CI386RedSea *volume,CI386Ata *disk,I64 start);
import Bool I386RedSeaMoveIntentSet(CI386RedSea *volume,I64 source_parent,Bool source_root,
  U8 *source_name,I64 destination_parent,Bool destination_root,U8 *destination_name,
  CI386RedSeaEntry *source,Bool transfer=FALSE);
import Bool I386RedSeaMoveIntentClear(CI386RedSea *volume);
import I64 I386RedSeaWrite(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count);
import Bool I386RedSeaDirectory(CI386RedSea *volume,I64 block,U8 *sector,I64 *size);
import U0 I386RedSeaPutWord(U8 *p,U64 value);
import U0 KernelLog(U8 *text);
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
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
U8 *I386FileRuntimeTmpFilename()
{
  return file_compiler.tmp_filename;
}
U8 I386FileRuntimeDriveAlias(U8 alias)
{
  CFilePathContext paths;
  CI386FileVolumes *volumes;
  CI386TaskFiles *state=I386TaskFilesBorrow(I386TaskSelf,&paths,&volumes);
  U8 result=0;
  if(!state) throw('Drv');
  if(!alias) result=paths.cur_drv;
  else if(alias==':') result=paths.boot_drv;
  else if(alias=='~' && paths.home_dir) result=*paths.home_dir;
  else result=alias;
  if(!I386TaskFilesRelease(state)) throw('Drv');
  return result;
}
U32 file_runtime_version=I386_FILE_SERVICES_VERSION;
Bool I386FileRuntimeExportAt(I64 index,CI386ModuleBinding *binding)
{
  if(!binding || index<0 || index>2) return FALSE;
  binding->kind=I386_MODULE_EXPORT;
  if(!index){binding->name="I386ArcEntryGet";binding->address=(&I386ArcEntryGet+0)(U64);}
  else if(index==1){binding->name="I386TaskModuleStageNew";binding->address=(&I386TaskModuleStageNew+0)(U64);}
  else {binding->name="I386TaskModuleStageCleanup";binding->address=(&I386TaskModuleStageCleanup+0)(U64);}
  return TRUE;
}
#assert sizeof(CI386FileServices)==120
I64 Main(CI386FileServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386FileServices)) return 0;
  services->version=file_runtime_version; services->bytes=sizeof(CI386FileServices);
  services->include=&I386LexTaskFileInclude; services->read=&I386TaskFileRead;
  services->public_reader=&I386TaskFilePublicReader; services->read_raw=&I386TaskFileReadRaw; services->read_stored=&I386TaskFileReadStored; services->expand=&I386ExpandBuf; services->find_public=&I386TaskFileFind; services->cd=&I386TaskCd;
  services->install_boot=&I386TaskInstallBoot;
  services->install_image=&I386TaskInstallBootImage;
  services->name_abs=&I386TaskFileNameAbs;
  services->bind=&I386FileRuntimeBind; services->init=&I386TaskFilesInit;
  services->compiler_init=&I386FileRuntimeCompiler; services->control_new=&I386FileRuntimeControl;
  services->tmp_filename=&I386FileRuntimeTmpFilename;
  services->drive_alias=&I386FileRuntimeDriveAlias;
  services->cancel_wait=&I386FileRuntimeCancelWait;
  services->write=&I386TaskFileWrite; services->write_public=&I386TaskFileWritePublic;
  services->dir_mk=&I386TaskDirMk;
  services->dir_list=&I386TaskDirList;
  services->del=&I386TaskFileDelete;
  services->rename=&I386TaskFileRename;
  services->dir_del=&I386TaskDirDelete;
  services->move=&I386TaskFileMove;
  services->move_probe=&I386TaskFileMoveProbe;
  services->move_io_probe=&I386TaskFileMoveIoProbe;
  services->export_at=&I386FileRuntimeExportAt;
  return 1;
}
#include "/Kernel/I386/FileNames.HC"
#include "/Kernel/I386/FilePaths.HC"
#include "/Kernel/I386/Arc.HC"
#include "/Kernel/I386/ArcExpand.HC"
#include "/Kernel/I386/Expand.HC"
#include "/Kernel/I386/FileLoad.HC"
#include "/Kernel/I386/ResidentFiles.HC"
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
#include "/Kernel/I386/Compress.HC"
#include "/Kernel/I386/TaskFileWrite.HC"
#include "/Kernel/I386/TaskFileFind.HC"
#include "/Kernel/I386/InstallBootArea.HC"
#include "/Kernel/I386/TaskCompiler.HC"

#include "/Kernel/I386/TaskCd.HC"

#include "/Kernel/I386/TaskModuleStage.HC"
