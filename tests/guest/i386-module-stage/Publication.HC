#include "/Kernel/I386/ModulePublishCore.HC"
CI386ModulePublish mp;
I64 mp_block,mp_checks,mp_flushes,mp_writes,mp_reclaims,mp_observes,mp_unsafe;
I64 mp_fail_flush,mp_write_mode,mp_reclaim_mode;
U32 mp_durable,mp_observed;
Bool mp_pending,mp_flush_persists;
U0 MPAssert(Bool value){mp_checks++;if(!value)throw('Publish',TRUE);}
Bool MPFlush(U8 *context)
{
  no_warn context;mp_flushes++;
  if(mp_flushes==mp_fail_flush && !mp_flush_persists)return FALSE;
  if(mp_pending){mp_durable=I386_PUBLISH_NEW;mp_pending=FALSE;}
  return mp_flushes!=mp_fail_flush;
}
Bool MPWrite(U8 *context)
{
  no_warn context;mp_writes++;
  if(mp.phase!=I386_PUBLISH_UNCERTAIN || I386ModulePublishAbortable(&mp) || mp_block!=2056)mp_unsafe++;
  if(mp_write_mode==1)return FALSE;
  mp_pending=TRUE;
  if(mp_write_mode==3)throw('Write',TRUE);
  return mp_write_mode!=2;
}
U32 MPObserve(U8 *context)
{no_warn context;mp_observes++;if(mp_pending)mp_unsafe++;if(mp_observed==4)return mp_durable;return mp_observed;}
Bool MPReclaim(U8 *context)
{
  no_warn context;mp_reclaims++;
  if(mp_block || mp.phase!=I386_PUBLISH_COMMITTED || mp_durable!=I386_PUBLISH_NEW)mp_unsafe++;
  if(mp_reclaims==1 && mp_reclaim_mode==2)throw('Reclaim',TRUE);
  return !(mp_reclaims==1 && mp_reclaim_mode==1);
}
U0 MPReset()
{
  MemSet(&mp,0,sizeof(CI386ModulePublish));mp_block=2056;
  mp_flushes=mp_writes=mp_reclaims=mp_observes=0;
  mp_fail_flush=mp_write_mode=mp_reclaim_mode=0;
  mp_pending=mp_flush_persists=FALSE;mp_durable=mp_observed=I386_PUBLISH_OLD;
  if(!I386ModulePublishInit(&mp,0,&mp_block,&MPFlush,&MPWrite,&MPObserve,&MPReclaim))throw('Init',TRUE);
}
Bool MPRecover()
{mp_observed=4;return I386ModulePublishRecover(&mp);}
U0 MPContract()
{
  Bool caught;
  mp_checks=mp_unsafe=0;
  MPReset;MPAssert(I386ModulePublishCommit(&mp) && !mp_block && mp.phase==I386_PUBLISH_DONE && mp_durable==2 && mp_reclaims==1);
  MPAssert(I386ModulePublishCommit(&mp) && mp_writes==1 && mp_flushes==2 && mp_reclaims==1);
  MPAssert(!I386ModulePublishAbortable(&mp));
  MPReset;mp_fail_flush=1;
  MPAssert(!I386ModulePublishCommit(&mp) && I386ModulePublishAbortable(&mp) && mp_block==2056 && !mp_writes && !mp_reclaims);
  mp_fail_flush=0;MPAssert(I386ModulePublishCommit(&mp));
  MPReset;mp_write_mode=1;
  MPAssert(!I386ModulePublishCommit(&mp) && mp.phase==2 && mp_block==2056);
  MPAssert(!I386ModulePublishAbortable(&mp) && !I386ModulePublishCommit(&mp) && mp_writes==1);
  MPAssert(!MPRecover && I386ModulePublishAbortable(&mp) && mp_block==2056);
  mp_write_mode=0;MPAssert(I386ModulePublishCommit(&mp));
  MPReset;mp_write_mode=2;
  MPAssert(!I386ModulePublishCommit(&mp) && mp.phase==2 && mp_durable==1 && mp_pending);
  MPAssert(MPRecover && !mp_block && mp_durable==2 && mp.phase==4);
  MPReset;mp_fail_flush=2;
  MPAssert(!I386ModulePublishCommit(&mp) && mp.phase==2 && mp_pending && mp_durable==1);
  mp_fail_flush=0;MPAssert(MPRecover && mp.phase==4);
  MPReset;mp_fail_flush=2;mp_flush_persists=TRUE;
  MPAssert(!I386ModulePublishCommit(&mp) && mp.phase==2 && mp_durable==2 && mp_block==2056);
  mp_fail_flush=3;mp_flush_persists=FALSE;
  MPAssert(!MPRecover && !mp_observes && mp_block==2056);
  mp_fail_flush=0;MPAssert(MPRecover && !mp_block);
  MPReset;mp_write_mode=1;I386ModulePublishCommit(&mp);mp_observed=3;
  MPAssert(!I386ModulePublishRecover(&mp) && mp.phase==2 && mp_block==2056 && !I386ModulePublishAbortable(&mp));
  MPAssert(!MPRecover && I386ModulePublishAbortable(&mp));
  MPReset;mp_reclaim_mode=1;
  MPAssert(!I386ModulePublishCommit(&mp) && mp.phase==3 && !mp_block && mp_durable==2);
  MPAssert(!I386ModulePublishAbortable(&mp));
  MPAssert(MPRecover && mp_reclaims==2 && mp_writes==1 && mp_flushes==2);
  MPReset;mp_write_mode=3;caught=FALSE;
  try {I386ModulePublishCommit(&mp);}catch {Fs->catch_except=TRUE;caught=TRUE;}
  MPAssert(caught && mp.phase==2 && mp_block==2056 && !I386ModulePublishAbortable(&mp));
  MPAssert(MPRecover && !mp_block);
  MPReset;mp_reclaim_mode=2;caught=FALSE;
  try {I386ModulePublishCommit(&mp);}catch {Fs->catch_except=TRUE;caught=TRUE;}
  MPAssert(caught && mp.phase==3 && !mp_block);
  MPAssert(MPRecover && mp_reclaims==2);
  MPReset;MPAssert(!I386ModulePublishInit(0,0,&mp_block,&MPFlush,&MPWrite,&MPObserve,&MPReclaim));
  MemSet(&mp,0,sizeof(CI386ModulePublish));mp_block=0;
  MPAssert(!I386ModulePublishInit(&mp,0,&mp_block,&MPFlush,&MPWrite,&MPObserve,&MPReclaim));
  mp_block=2056;MPAssert(!I386ModulePublishInit(&mp,0,&mp_block,0,&MPWrite,&MPObserve,&MPReclaim));
  MPReset;MPAssert(!I386ModulePublishInit(&mp,0,&mp_block,&MPFlush,&MPWrite,&MPObserve,&MPReclaim));
  MPAssert(!I386ModulePublishAbortable(0) && !I386ModulePublishCommit(0) && !I386ModulePublishRecover(0));
  MPReset;mp_write_mode=1;I386ModulePublishCommit(&mp);mp_observed=0;
  MPAssert(!I386ModulePublishRecover(&mp) && mp.phase==2 && mp_block==2056);
  MPAssert(!MPRecover && I386ModulePublishAbortable(&mp));
  MPAssert(!mp_unsafe);
}
U0 MPReport(U8 *line){while(*line)OutU8(0xE9,*line++);}
U0 MPRun()
{
  Bool passed=FALSE;U8 *line;
  try {MPContract;passed=mp_checks==33;}catch {Fs->catch_except=TRUE;}
  if(passed)line=MStrPrint("DONE stage-publication %d checks\n",mp_checks);
  else line=MStrPrint("FAIL stage-publication %d checks\n",mp_checks);
  MPReport(line);Free(line);
}
MPRun;
