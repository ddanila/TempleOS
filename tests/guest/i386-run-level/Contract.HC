#include "/Kernel/HashExportTypes.HH"
class CRunLevelObservation
{
  U32 seen;
  Bool done;
};
U0 RunLevelWorker(U8 *data)
{
  CRunLevelObservation *observation=data;
  observation->seen=sys_run_level;
  LBts(&sys_run_level,RLf_AUTO_COMPLETE);
  observation->done=TRUE;
}
I64 RunLevelContract()
{
  U32 required=RLF_16BIT|RLF_VGA|RLF_32BIT|RLF_RAW|RLF_INTERRUPTS|
    RLF_BLKDEV|RLF_COMPILER|RLF_DOC|RLF_WINMGR|RLF_REGISTRY|RLF_ADAM_SERVER;
  U32 saved=sys_run_level;
  CRunLevelObservation observation;
  CHashExport *symbol=HashFind("_SYS_RUN_LEVEL",Fs->hash_table,HTT_EXPORT_SYS_SYM);
  CTask *child=NULL;
  I64 mask=0;
  observation.seen=0;observation.done=FALSE;
  if(saved==required)mask|=1;
  if(sizeof(sys_run_level)==4 && symbol && symbol->val==(&sys_run_level+0)(U64))mask|=2;
  try {
    child=Spawn(&RunLevelWorker,&observation,"RunLevel",-1,Fs,8192);
    if(child) {
      DeathWait(&child);
      if(observation.done && observation.seen==saved &&
          sys_run_level==(saved|RLF_AUTO_COMPLETE))mask|=4;
    }
  } catch {Fs->catch_except=TRUE;}
  //The autocomplete task is not active in this isolated fixture.
  sys_run_level=saved;
  return mask;
}
