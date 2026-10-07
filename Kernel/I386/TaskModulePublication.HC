//Publication provider code must outlive every registered cleanup callback.
#include "/Kernel/I386/TaskModulePublication.HH"
#include "/Kernel/I386/RedSeaPublication.HC"
Bool I386TaskModulePublicationCleanup(U8 *context)
{
  CI386TaskModulePublication *owned=context;
  CI386TaskModuleStage *stage=owned->stage;
  CI386RedSeaPublication *p=&owned->publication;
  CI386RedSeaIo *io=stage->volume->io;
  U32 phase=p->transaction.phase;
  Bool resolved=FALSE;
  if(stage->publication!=&owned->resource ||
      (phase && (p->shared!=stage->volume || p->transaction.owned_block!=&stage->block)))return FALSE;
  if(phase==I386_PUBLISH_UNCERTAIN || phase==I386_PUBLISH_COMMITTED) {
    if(!io || !io->begin || !io->end || !(*io->begin)(io->context))return FALSE;
    resolved=I386RedSeaPublicationRecover(p);
    if(p->transaction.phase==I386_PUBLISH_PREPARED)resolved=TRUE;
    if(!(*io->end)(io->context)){stage->volume->signature=0;return FALSE;}
    if(!resolved)return FALSE;
    phase=p->transaction.phase;
  }
  if(phase && phase!=I386_PUBLISH_PREPARED && phase!=I386_PUBLISH_DONE)return FALSE;
  if(phase==I386_PUBLISH_DONE && stage->block)return FALSE;
  if(!I386HeapFree(stage->owner->heap,owned))return FALSE;
  stage->publication=0;return TRUE;
}
CI386RedSeaPublication *I386TaskModulePublicationNew(CI386ModuleStage *unit)
{
  CI386TaskModuleStage *stage=unit;
  CI386TaskModulePublication *owned;
  U32 flags=I386IrqSave;
  CI386RedSeaPublication *result=0;
  if(!stage || !unit->owned || unit->phase!=I386_STAGE_READY || stage->active ||
      !stage->block || stage->publication || !stage->owner ||
      stage->owner->task!=I386TaskSelf || stage->owner->stage!=&stage->resource)goto publication_new_done;
  owned=I386HeapAlloc(stage->owner->heap,sizeof(CI386TaskModulePublication),TRUE);
  if(!owned)goto publication_new_done;
  owned->stage=stage;owned->resource.context=owned;
  owned->resource.cleanup=&I386TaskModulePublicationCleanup;
  stage->publication=&owned->resource;result=&owned->publication;
publication_new_done:
  I386IrqRestore(flags);return result;
}
