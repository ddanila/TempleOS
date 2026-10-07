//Caller holds the complete disk lease and retains this record across failures.
#include "/Kernel/I386/ModulePublish.HH"
Bool I386ModulePublishInit(CI386ModulePublish *p,U8 *context,I64 *owned_block,
  Bool (*flush)(U8 *context),Bool (*write)(U8 *context),
  U32 (*observe)(U8 *context),Bool (*reclaim)(U8 *context))
{
  if(!p || p->phase || !owned_block || *owned_block<=0 ||
      !flush || !write || !observe || !reclaim)return FALSE;
  p->context=context;p->owned_block=owned_block;p->flush=flush;p->write=write;
  p->observe=observe;p->reclaim=reclaim;p->phase=I386_PUBLISH_PREPARED;return TRUE;
}
Bool I386ModulePublishFinish(CI386ModulePublish *p)
{//New extent belongs to the directory before reclaiming the old extent.
  p->phase=I386_PUBLISH_COMMITTED;*p->owned_block=0;
  if(!(*p->reclaim)(p->context))return FALSE;
  p->phase=I386_PUBLISH_DONE;return TRUE;
}
Bool I386ModulePublishCommit(CI386ModulePublish *p)
{
  if(!p)return FALSE;
  if(p->phase==I386_PUBLISH_DONE)return TRUE;
  if(p->phase==I386_PUBLISH_COMMITTED)return I386ModulePublishFinish(p);
  if(p->phase!=I386_PUBLISH_PREPARED || *p->owned_block<=0)return FALSE;
  //Data and reservation must be durable before the directory can expose them.
  if(!(*p->flush)(p->context))return FALSE;
  p->phase=I386_PUBLISH_UNCERTAIN;
  if(!(*p->write)(p->context) || !(*p->flush)(p->context))return FALSE;
  return I386ModulePublishFinish(p);
}
Bool I386ModulePublishRecover(CI386ModulePublish *p)
{//Flush pending writes before interpreting an exact old/new slot observation.
  U32 observed;
  if(!p)return FALSE;
  if(p->phase==I386_PUBLISH_COMMITTED || p->phase==I386_PUBLISH_DONE)
    return I386ModulePublishCommit(p);
  if(p->phase!=I386_PUBLISH_UNCERTAIN || !(*p->flush)(p->context))return FALSE;
  observed=(*p->observe)(p->context);
  if(observed==I386_PUBLISH_NEW)return I386ModulePublishFinish(p);
  if(observed==I386_PUBLISH_OLD)p->phase=I386_PUBLISH_PREPARED;
  return FALSE;
}
Bool I386ModulePublishAbortable(CI386ModulePublish *p)
{//An ambiguous directory write must prevent ordinary staging cleanup.
  if(!p || p->phase!=I386_PUBLISH_PREPARED || !p->owned_block)return FALSE;
  return *p->owned_block>0;
}
