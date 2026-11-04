class CRunLevelReferenceObservation { U32 seen;Bool done; };
U0 RunLevelReferenceWorker(U8 *data)
{
  CRunLevelReferenceObservation *observation=data;
  observation->seen=sys_run_level;
  LBts(&sys_run_level,RLf_AUTO_COMPLETE);
  observation->done=TRUE;
}
I64 RunLevelReferenceContract()
{
  U32 saved=sys_run_level,cleared=saved&~RLF_AUTO_COMPLETE;
  CRunLevelReferenceObservation observation;
  CHashExport *symbol=HashFind("SYS_RUN_LEVEL",Fs->hash_table,HTT_EXPORT_SYS_SYM);
  CTask *child=NULL;
  I64 mask=0;
  observation.seen=0;observation.done=FALSE;
  if(sizeof(sys_run_level)==4 && symbol && symbol->val==(&sys_run_level+0)(U64))mask|=1;
  if((saved&(RLF_COMPILER|RLF_BLKDEV|RLF_DOC|RLF_REGISTRY))==
      (RLF_COMPILER|RLF_BLKDEV|RLF_DOC|RLF_REGISTRY) &&
      !(saved&RLF_ADAM_SERVER))mask|=2;
  sys_run_level=cleared;
  try {
    child=Spawn(&RunLevelReferenceWorker,&observation,"RunLevel",-1,Fs,8192);
    if(child) {
      DeathWait(&child);
      if(observation.done && observation.seen==cleared &&
          sys_run_level==(cleared|RLF_AUTO_COMPLETE))mask|=4;
    }
  } catch {Fs->catch_except=TRUE;}
  sys_run_level=saved;
  return mask;
}
