//Allocation-free staging lifecycle. Transport has already registered ownership.
#include "/Kernel/I386/ModuleStage.HH"
Bool I386ModuleStageInit(CI386ModuleStage *stage,I64 bytes,U8 *context,
  I64 (*write)(U8 *context,U32 offset,U8 *buffer,U32 bytes),
  Bool (*flush)(U8 *context),I64 (*read)(U8 *context,U8 *buffer,I64 bytes),
  Bool (*release)(U8 *context))
{
  if(!stage || stage->phase || stage->owned || bytes<32 || bytes>4194304 ||
      !write || !flush || !read || !release)return FALSE;
  stage->context=context;stage->bytes=bytes;stage->written=0;
  stage->write=write;stage->flush=flush;stage->read=read;stage->release=release;
  stage->owned=TRUE;stage->phase=I386_STAGE_OPEN;return TRUE;
}
I64 I386ModuleStageWrite(U8 *context,U32 offset,U8 *buffer,U32 bytes)
{
  CI386ModuleStage *stage=context;
  I64 result;
  if(!stage || !stage->owned || stage->phase!=I386_STAGE_OPEN ||
      !buffer || !bytes || bytes>4096 || offset!=stage->written ||
      bytes>stage->bytes-stage->written)return 0;
  result=(*stage->write)(stage->context,offset,buffer,bytes);
  if(result!=bytes){stage->phase=I386_STAGE_FAILED;return 0;}
  stage->written+=bytes;return bytes;
}
Bool I386ModuleStageSeal(CI386ModuleStage *stage)
{
  if(!stage || !stage->owned || stage->phase!=I386_STAGE_OPEN ||
      stage->written!=stage->bytes)return FALSE;
  if(!(*stage->flush)(stage->context)){stage->phase=I386_STAGE_FAILED;return FALSE;}
  stage->phase=I386_STAGE_SEALED;return TRUE;
}
Bool I386ModuleStageUnwound(CI386ModuleStage *stage,Bool clean)
{
  if(!stage || !stage->owned || stage->phase!=I386_STAGE_SEALED)return FALSE;
  if(!clean){stage->phase=I386_STAGE_FAILED;return FALSE;}
  stage->phase=I386_STAGE_READY;return TRUE;
}
Bool I386ModuleStageRead(CI386ModuleStage *stage,U8 *buffer,I64 bytes)
{
  if(!stage || !stage->owned || stage->phase!=I386_STAGE_READY ||
      !buffer || bytes!=stage->bytes)return FALSE;
  if((*stage->read)(stage->context,buffer,bytes)!=bytes) {
    stage->phase=I386_STAGE_FAILED;return FALSE;
  }
  stage->phase=I386_STAGE_READ;return TRUE;
}
Bool I386ModuleStageRelease(CI386ModuleStage *stage)
{//Release failures retain ownership, including after read/write/flush failures.
  if(!stage)return FALSE;
  if(stage->phase==I386_STAGE_RELEASED && !stage->owned)return TRUE;
  if(!stage->owned || !stage->phase)return FALSE;
  if(!(*stage->release)(stage->context))return FALSE;
  stage->owned=FALSE;stage->phase=I386_STAGE_RELEASED;return TRUE;
}
