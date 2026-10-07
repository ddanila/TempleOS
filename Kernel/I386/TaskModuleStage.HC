#include "/Kernel/I386/TaskModuleStage.HH"
#include "/Kernel/I386/ModuleStageCore.HC"
I64 I386TaskModuleStageWrite(U8 *context,U32 offset,U8 *buffer,U32 bytes)
{
  CI386TaskModuleStage *stage=context;
  CI386RedSeaEntry entry;
  I64 result=-1;
  U32 flags=I386IrqSave;
  stage->active=TRUE;
  entry.attr=0x800;entry.block=stage->block;entry.size=stage->unit.bytes;
  if(I386RedSeaBegin(stage->volume)) {
    result=I386RedSeaWrite(stage->volume,&entry,offset,buffer,bytes);
    if(!I386RedSeaEnd(stage->volume)){stage->volume->signature=0;result=-1;}
  }
  stage->active=FALSE;I386IrqRestore(flags);return result;
}
Bool I386TaskModuleStageFlush(U8 *context)
{
  CI386TaskModuleStage *stage=context;
  Bool result=FALSE;
  U32 flags=I386IrqSave;
  stage->active=TRUE;
  if(I386RedSeaBegin(stage->volume)) {
    result=I386RedSeaFlush(stage->volume);
    if(!I386RedSeaEnd(stage->volume)){stage->volume->signature=0;result=FALSE;}
  }
  stage->active=FALSE;I386IrqRestore(flags);return result;
}
I64 I386TaskModuleStageRead(U8 *context,U8 *buffer,I64 bytes)
{
  CI386TaskModuleStage *stage=context;
  CI386RedSeaEntry entry;
  I64 result=-1;
  U32 flags=I386IrqSave;
  stage->active=TRUE;
  entry.attr=0x800;entry.block=stage->block;entry.size=stage->unit.bytes;
  if(I386RedSeaBegin(stage->volume)) {
    result=I386RedSeaRead(stage->volume,&entry,0,buffer,bytes);
    if(!I386RedSeaEnd(stage->volume)){stage->volume->signature=0;result=-1;}
  }
  stage->active=FALSE;I386IrqRestore(flags);return result;
}
Bool I386TaskModuleStageRelease(U8 *context)
{
  CI386TaskModuleStage *stage=context;
  CI386RedSea *volume=stage->volume,private_volume;
  CI386RedSeaIo *io=volume->io;
  Bool result=FALSE;
  U32 flags=I386IrqSave;
  stage->active=TRUE;
  if(!stage->block){result=TRUE;goto stage_release_done;}
  //Acquire the channel directly: an invalid mounted view cannot Begin.
  if(!io || !io->begin || !io->end || !(*io->begin)(io->context))goto stage_release_done;
  if(!I386RedSeaValid(volume)) {
    //This private remount is never published. Other allocators stay quarantined.
    if(!I386RedSeaMount(&private_volume,volume->disk,volume->start))goto stage_release_end;
    private_volume.io=io;volume=&private_volume;
  }
  result=I386RedSeaReleaseOwned(volume,stage->block,stage->blocks) && I386RedSeaFlush(volume);
  if(!result)stage->volume->signature=0;
stage_release_end:
  if(!(*io->end)(io->context)){stage->volume->signature=0;result=FALSE;}
  if(result)stage->block=0;
stage_release_done:
  stage->active=FALSE;I386IrqRestore(flags);return result;
}
Bool I386TaskModuleStageCleanup(U8 *context)
{
  CI386TaskModuleStage *stage=context;
  CI386TaskFiles *owner=stage->owner;
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  if(owner->stage!=&stage->resource || (stage->active && !owner->task->finished) ||
      ((stage->unit.phase || stage->unit.owned) && !I386ModuleStageRelease(&stage->unit)))goto stage_cleanup_done;
  if(!I386HeapFree(owner->heap,stage))goto stage_cleanup_done;
  owner->stage=0;result=TRUE;
stage_cleanup_done:
  I386IrqRestore(flags);return result;
}
Bool I386TaskModuleStageReserve(CI386ModuleStage *unit,I64 bytes)
{
  CI386TaskModuleStage *stage=unit;
  I64 reserved;
  U32 flags=I386IrqSave,count;
  Bool ready=FALSE;
  if(!stage || stage->owner->stage!=&stage->resource ||
      !I386ModuleStageInit(unit,bytes,stage,&I386TaskModuleStageWrite,
        &I386TaskModuleStageFlush,&I386TaskModuleStageRead,&I386TaskModuleStageRelease))goto stage_reserve_done;
  count=bytes;stage->blocks=(count+511)/512;stage->active=TRUE;
  if(I386RedSeaBegin(stage->volume)) {
    reserved=I386RedSeaAllocOwned(stage->volume,stage->blocks,&stage->block);
    ready=reserved>0 && I386RedSeaFlush(stage->volume);
    if(!I386RedSeaEnd(stage->volume)){stage->volume->signature=0;ready=FALSE;}
  }
  stage->active=FALSE;
  if(!ready)unit->phase=I386_STAGE_FAILED;
stage_reserve_done:
  I386IrqRestore(flags);return ready;
}
CI386ModuleStage *I386TaskModuleStageNew(U8 *target,I64 bytes)
{//Zero bytes prepares a task resource before compiler allocations; reserve later.
  CI386Task *task=I386TaskSelf;
  CI386TaskFiles *owner;
  CI386TaskModuleStage *stage=0;
  CI386RedSea *volume;
  U32 flags=I386IrqSave,drive;
  Bool ready=FALSE;
  if((bytes && bytes<32) || bytes>4194304 || !target || !*target ||
      target[1]!=':' || target[2]!='/')goto stage_new_done;
  owner=I386TaskFilesValid(task);
  if(!owner || !I386TaskFilesAccess(task) || !task->owner || task->finished ||
      task->finishing || owner->busy || owner->stage)goto stage_new_done;
  drive=target[0];if('a'<=drive<='z')drive-=32;
  if(drive<'A' || drive>'Z' || !(volume=owner->volumes->letter[drive-'A']) ||
      !volume->io || !I386RedSeaValid(volume))goto stage_new_done;
  stage=I386HeapAlloc(owner->heap,sizeof(CI386TaskModuleStage),TRUE);
  if(!stage)goto stage_new_done;
  stage->owner=owner;stage->volume=volume;
  stage->unit.reserve=&I386TaskModuleStageReserve;
  stage->unit.emit=&I386ModuleStageWrite;stage->unit.seal=&I386ModuleStageSeal;
  stage->unit.unwound=&I386ModuleStageUnwound;stage->unit.readback=&I386ModuleStageRead;
  stage->resource.context=stage;stage->resource.cleanup=&I386TaskModuleStageCleanup;
  owner->stage=&stage->resource;
  ready=TRUE;
  if(bytes)ready=I386TaskModuleStageReserve(&stage->unit,bytes);
  if(!ready) {I386TaskModuleStageCleanup(stage);stage=0;}
stage_new_done:
  I386IrqRestore(flags);if(ready)return &stage->unit;return 0;
}
