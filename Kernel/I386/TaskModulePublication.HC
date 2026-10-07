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
CI386RedSeaPublication *I386TaskModulePublicationNew(CI386ModuleStage *unit,U8 *target=0)
{
  CI386TaskModuleStage *stage=unit;
  CI386TaskModulePublication *owned;
  U32 flags=I386IrqSave;
  I64 length=0,i;
  CI386RedSeaPublication *result=0;
  if(!stage || !unit->owned || unit->phase!=I386_STAGE_READY || stage->active ||
      !stage->block || stage->publication || !stage->owner ||
      stage->owner->task!=I386TaskSelf || stage->owner->stage!=&stage->resource)goto publication_new_done;
  if(target) {
    while(target[length] && length<4096)length++;
    if(!length || length==4096)goto publication_new_done;
  }
  owned=I386HeapAlloc(stage->owner->heap,sizeof(CI386TaskModulePublication)+length+1,TRUE);
  if(!owned)goto publication_new_done;
  if(target) {
    owned->target=(owned+1)(U8 *);
    for(i=0;i<=length;i++)owned->target[i]=target[i];
  }
  owned->stage=stage;owned->resource.context=owned;
  owned->resource.cleanup=&I386TaskModulePublicationCleanup;
  stage->publication=&owned->resource;result=&owned->publication;
publication_new_done:
  I386IrqRestore(flags);return result;
}

Bool I386TaskModulePublish(CI386ModuleStage *unit,U8 *target)
{//Publish only on the staged volume; the registered record owns the path copy.
  CI386TaskModuleStage *stage=unit;
  CI386RedSeaPublication *p;
  CI386TaskModulePublication *owned;
  CI386RedSeaEntry parent;
  U8 *path,*leaf,*cursor;
  U32 flags=I386IrqSave,drive;
  I64 status;
  Bool result=FALSE;
  if(!stage || !target || !target[0] || target[1]!=':' || target[2]!='/')
    goto module_publish_done;
  drive=target[0];if('a'<=drive<='z')drive-=32;
  if(drive<'A' || drive>'Z' || !stage->owner ||
      stage->owner->volumes->letter[drive-'A']!=stage->volume)
    goto module_publish_done;
  p=I386TaskModulePublicationNew(unit,target);
  if(!p)goto module_publish_done;
  owned=stage->publication->context;path=owned->target+2;leaf=path;cursor=path;
  while(*cursor){if(*cursor=='/')leaf=cursor+1;cursor++;}
  if(!I386RedSeaNewName(leaf))goto module_publish_done;
  stage->active=TRUE;
  if(I386RedSeaBegin(stage->volume)) {
    parent.block=0;
    if(leaf==path+1)parent.block=stage->volume->root;
    else {
      leaf[-1]=0;
      status=I386RedSeaResolve(stage->volume,stage->volume->root,path,&parent);
      leaf[-1]='/';
      if(status!=1 || !(parent.attr&0x10))parent.block=0;
    }
    if(parent.block && I386RedSeaPublicationPrepare(p,stage->volume,parent.block,
        leaf,&stage->block,unit->bytes)==1)
      result=I386RedSeaPublicationCommit(p);
    if(!I386RedSeaEnd(stage->volume)){stage->volume->signature=0;result=FALSE;}
  }
  stage->active=FALSE;
module_publish_done:
  I386IrqRestore(flags);return result;
}
