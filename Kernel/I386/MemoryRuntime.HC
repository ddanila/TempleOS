//Kernel-lifetime backing provider and public task heap ownership.
#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define I386_MEMORY_FAILURE_TRACE 1
#include "/Kernel/I386/MemoryRuntime.HH"
#include "/Kernel/I386/MemoryBacking.HH"
#include "/Kernel/I386/MemoryBackingConfig.HH"
#include "/Kernel/I386/TaskHeaps.HH"
#include "/Kernel/I386/TaskSymbols.HH"
#include "/Kernel/I386/Cpu.HH"
#include "/Kernel/I386/KernelSymbols.HH"
#include "/Kernel/I386/MemoryPublic.HH"
#include "/Kernel/I386/HashPublic.HH"
#include "/Kernel/TimeTypes.HH"
#include "/Kernel/SemaTypes.HH"
import CCntsGlbls cnts;
import Bool I386SchedYield(CI386Scheduler *s);
import U8 *I386HeapAlloc(CI386Heap *heap,I64 size,Bool zero=FALSE);
import Bool I386HeapFree(CI386Heap *heap,U8 *ptr);
import Bool I386HeapShrink(CI386Heap *heap,U8 *ptr,I64 size);
import I64 I386HeapSize(CI386Heap *heap,U8 *ptr);
import Bool I386HeapValid(CI386Heap *heap);
import U32 I386IrqSave();
import U0 I386IrqRestore(U32 flags);
import U0 KernelLog(U8 *text);
import U0 KernelHex(U64 value);
import U0 KernelStop();
import U0 HashAdd(CHash *entry,CHashTable *table);
import U0 SysTry(U8 *catch_start,U8 *untry_start);
import U0 SysUntry();
import CHash *HashFind(U8 *name,CHashTable *table,I64 mask,I64 instance=1);
import U0 throw(I64 ch=0,Bool no_log=FALSE);
CI386BackingPool memory_pool;
CI386Task *memory_root;
CTask *adam_task;
U32 memory_runtime_version=I386_MEMORY_SERVICES_VERSION;
CI386KernelSymbol memory_exports[47];
CSema memory_semas[SEMA_SEMAS_NUM];
CJob memory_macro_head;
CTask *memory_macro_task;
extern U0 MemoryTaskRootInit(CI386Task *root);
extern Bool MemoryTaskValidate(CTask *task);
extern Bool MemoryManagedYield(CI386Scheduler *scheduler);
extern CTask *Spawn(U0 (*entry)(U8 *data),U8 *data=0,U8 *name=0,I64 target_cpu=-1,CTask *parent=0,I64 stack_size=0,I64 flags=256);
extern U0 Exit();
extern U0 TaskQueIns(CTask *task,CTask *pred=0);
extern CJob *MemoryTaskMsg(CTask *task,CTask *master,I64 msg_code,I64 arg1,I64 arg2,I64 flags);
extern U0 MemoryPostKeyTimed(CTask *task,I64 code,I64 a,I64 b,I64 flags,I64 arrival);
extern I64 MemoryScanTimed(I64 *a,I64 *b,I64 mask,CTask *task,I64 *arrival);
extern U0 MemoryPostMsg(CTask *task,I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
extern U0 MemoryMsg(I64 msg_code,I64 arg1,I64 arg2,I64 flags=0);
extern Bool MemorySuspend(CTask *task=0,Bool state=TRUE);
extern Bool MemoryIsSuspended(CTask *task=0);
extern Bool MemoryKill(CTask *task,Bool wait=TRUE,Bool just_break=FALSE);
extern I64 MemoryJobsHndlr(I64 run_flags,CTask *task=0);
extern I64 MemoryScanMsg(I64 *arg1=0,I64 *arg2=0,I64 mask=~1,CTask *task=0);
extern I64 MemoryGetMsg(I64 *arg1=0,I64 *arg2=0,I64 mask=~1,CTask *task=0);
extern I64 MemoryFlushMsgs(CTask *task=0);
extern U0 MemoryReclaim(CI386PublicPool *pool);
extern U0 MemoryProbe(I64 phase);
extern U0 Yield();
extern U0 Sleep(I64 mS);
extern U0 SleepUntil(I64 wake_jiffy);
Bool MemoryBind(CI386Task *root,CI386Heap *heap,CHashTable *symbols)
{//Reserve startup pages early; subsequent public backing grows on demand.
  U32 flags=I386IrqSave;
  Bool result=FALSE;
  U8 *addresses[47],*names="_MALLOC\0_FREE\0_MSIZE\0_MSIZE2\0_MHEAP_CTRL\0_CALLOC\0_MALLOC_ALIGNED\0_CALLOC_ALIGNED\0_MEMCPY\0_MEMSET\0_MALLOC_IDENT\0_STR_NEW\0_STRCPY\0_BEQU\0_LBEQU\0_HASH_TABLE_NEW\0_HASH_TABLE_DEL\0_HASH_DEL\0_HASH_LIST_ADD\0_DEFINE_LIST_LOAD\0_HASH_DEFINE_LIST_ADD\0_MEM_MEASURE_START\0_MEM_MEASURE_STOP\0_YIELD\0_SLEEP\0_SLEEP_UNTIL\0_SPAWN\0_EXIT\0_TASK_QUE_INS\0I386SchedYield\0_TASK_MSG\0_POST_MSG\0_MSG\0_SUSPEND\0_IS_SUSPENDED\0_JOBS_HNDLR\0_SCAN_MSG\0_GET_MSG\0_FLUSH_MSGS\0_SYS_SEMAS\0_SYS_MACRO_HEAD\0_SYS_MACRO_TASK\0_KILL\0_HASH_REM_DEL\0_ADAM_TASK\0I386PostKeyTimed\0I386ScanKeyTimed\0";
  I64 i;
  if(memory_root || !symbols || !symbols->body || symbols->locked_flags ||
      !root || !root->gs || !root->owner || root->owner->root!=root ||
      root->owner->current!=root || !I386MemBackingInit(&memory_pool,heap,I386_NATIVE_BACKING_QUANTUM)) goto done;
  if(!I386MemBackingReserve(&memory_pool,I386_NATIVE_STARTUP_RESERVE_PAGES)) {
    if(!I386MemBackingDestroy(&memory_pool))KernelStop;
    goto done;
  }
  if(!I386TaskHeapsInit(root,heap,&memory_pool)) {
    if(!I386MemBackingDestroy(&memory_pool)) KernelStop;
    goto done;
  }
  memory_pool.reclaim=&MemoryReclaim; memory_root=root; result=TRUE;
  MemoryTaskRootInit(root); adam_task=root;
  memory_macro_head.next=memory_macro_head.last=&memory_macro_head;
  addresses[0]=&MemoryAlloc; addresses[1]=&MemoryFree; addresses[2]=&MemorySize;
  addresses[3]=&MemorySize2; addresses[4]=&MemoryHeap; addresses[5]=&MemoryCAlloc;
  addresses[6]=&MemoryAligned; addresses[7]=&MemoryCAligned;
  addresses[8]=&MemoryCopy; addresses[9]=&MemorySet;
  addresses[10]=&MemoryIdent; addresses[11]=&MemoryStrNew;
  addresses[12]=&MemoryStrCopy;
  addresses[13]=&MemoryBitEqu; addresses[14]=&MemoryLockedBitEqu;
  addresses[15]=&MemoryHashTableNew; addresses[16]=&MemoryHashTableDel;
  addresses[17]=&MemoryHashDel; addresses[18]=&MemoryHashLstAdd;
  addresses[19]=&MemoryDefineLstLoad; addresses[20]=&MemoryHashDefineLstAdd;
  addresses[21]=&MemoryMeasureStart; addresses[22]=&MemoryMeasureStop;
  addresses[23]=&Yield; addresses[24]=&Sleep; addresses[25]=&SleepUntil;
  addresses[26]=&Spawn; addresses[27]=&Exit; addresses[28]=&TaskQueIns;
  addresses[29]=&MemoryManagedYield;
  addresses[30]=&MemoryTaskMsg; addresses[31]=&MemoryPostMsg; addresses[32]=&MemoryMsg;
  addresses[33]=&MemorySuspend; addresses[34]=&MemoryIsSuspended;
  addresses[35]=&MemoryJobsHndlr;
  addresses[36]=&MemoryScanMsg; addresses[37]=&MemoryGetMsg; addresses[38]=&MemoryFlushMsgs;
  addresses[39]=memory_semas; addresses[40]=&memory_macro_head;
  addresses[41]=&memory_macro_task;
  addresses[42]=&MemoryKill; addresses[43]=&MemoryHashRemDel; addresses[44]=&adam_task;
  addresses[45]=&MemoryPostKeyTimed; addresses[46]=&MemoryScanTimed;
  for(i=0;i<47;i++) {
    memory_exports[i].str=names; memory_exports[i].type=HTT_EXPORT_SYS_SYM;
    memory_exports[i].kind=1;
    if(i>=39 && i<=41 || i==44) memory_exports[i].kind=3;
    memory_exports[i].val=(addresses[i]+0)(U64);
    HashAdd(&memory_exports[i],symbols);
    while(*names) names++;
    names++;
  }
done:
  I386IrqRestore(flags); return result;
}
I64 Main(CI386MemoryServices *services,I64 bytes)
{
  if(!services || bytes!=sizeof(CI386MemoryServices)) return 0;
  services->version=memory_runtime_version; services->bytes=bytes;
  services->bind=&MemoryBind; services->probe=&MemoryProbe;
  return 1;
}
U0 MemoryReclaim(CI386PublicPool *pool)
{//TaskHeapsDestroy has released its control and stopped reading page headers.
  if(pool!=&memory_pool || I386MemBackingTrim(&memory_pool)<0) KernelStop;
}
#include "/Kernel/I386/Bit.HC"
U0 Yield()
{
  CI386Task *task=I386TaskSelf;
  if(!task || !task->owner || !MemoryManagedYield(task->owner)) throw('Task',TRUE);
}
#include "/Kernel/I386/StrCopy.HC"
#include "/Kernel/I386/StrCopyCheck.HC"
U0 MemoryProbeReclaim(CI386PublicPool *pool)
{//Only the diagnostic pool; root graphics and startup reservations stay owned.
  if(I386MemBackingTrim(pool)<0) KernelStop;
}
U0 MemoryProbe(I64 phase)
{
  CI386Task *task=I386TaskSelf;
  CI386TaskHeaps *state=task->heap_state;
  U32 flags=I386IrqSave;
  CI386BackingPool probe_pool,root_before;
  CHeapCtrl saved_control;
  U8 *bytes;
  I64 i,before,allocations;
  U8 *p,*q;
  I64 capacity;
  if(!memory_root || !state || task->code_heap!=task->data_heap ||
      task->data_heap!=&state->control || state->control.mem_task!=task ||
      state->control.bp!=&memory_pool ||
      !phase && (task!=memory_root || state->parent) ||
      phase && (task==memory_root || state->parent!=memory_root->heap_state)) KernelStop;
  //Use the current task's empty control with a separate backing provider. The
  //control stays at its original address, so public selectors and ownership
  //callbacks remain real. IRQs stay masked; other tasks keep their live heaps.
  if(state->control.used_u8s || !I386MemHeapTrim(&state->control)) KernelStop;
  for(i=0;i<sizeof(CHeapCtrl);i++) (&saved_control)(U8 *)[i]=(&state->control)(U8 *)[i];
  for(i=0;i<sizeof(CI386BackingPool);i++) (&root_before)(U8 *)[i]=(&memory_pool)(U8 *)[i];
  bytes=&probe_pool; for(i=0;i<sizeof(CI386BackingPool);i++) bytes[i]=0;
  if(!I386MemHeapDestroy(&state->control) ||
      !I386MemBackingInit(&probe_pool,memory_pool.heap,I386_NATIVE_BACKING_QUANTUM)) KernelStop;
  probe_pool.reclaim=&MemoryProbeReclaim;
  if(!I386MemHeapInit(&state->control,&probe_pool,task) ||
      I386TaskHeapsValid(task)!=state) KernelStop;
  before=probe_pool.heap->used; allocations=probe_pool.heap->allocations;
  if(!StrCopyCheck(&MemoryStrCopy)) KernelStop;
  KernelLog("STRING COPY PROBE "); KernelHex(phase); KernelLog("\n");
  MemoryHashProbe;
  //Separate large allocations return pages immediately; a large request also
  //forces growth beyond the first region. Both regions must return to bootstrap.
  p=MemoryAlloc(2048,task); capacity=MemorySize(p);
  SetRFlags(GetRFlags|0x400);
  if(MemorySet(p,0x15A,capacity)!=p+capacity || GetRFlags&0x400) KernelStop;
  q=MemoryIdent(p,task->code_heap);
  if(!q || q==p || MemoryHeap(q)!=task->code_heap || MemorySize(q)<capacity ||
      q[0]!=90 || q[capacity-1]!=90) KernelStop;
  SetRFlags(GetRFlags|0x400);
  if(MemoryCopy(p,q,capacity)!=p+capacity || GetRFlags&0x400) KernelStop;
  MemoryFree(q); MemoryFree(p);
  if(MemoryIdent(0) || MemoryCopy(0,0,0) || MemorySet(0,1,0)) KernelStop;
  p=MemoryStrNew(0,task); q=MemoryStrNew("VGA",task->code_heap);
  if(p[0] || q[0]!='V' || q[1]!='G' || q[2]!='A' || q[3] ||
      MemoryHeap(p)!=task->data_heap || MemoryHeap(q)!=task->code_heap ||
      MemoryCopy(q+1,q,2)!=q+3 || q[1]!='V' || q[2]!='V' || q[3]) KernelStop;
  MemoryFree(p); MemoryFree(q);
  if(!I386MemHeapTrim(task->data_heap) || I386MemBackingTrim(&probe_pool)<0) KernelStop;
  p=MemoryAligned(2048,64,task,3); q=MemoryCAlloc(131000,task->code_heap);
  if(!p || !q || probe_pool.owned_count!=2 || MemorySize(p)<2048 ||
      MemorySize(q)<131000 || (p+0)(U64)%64!=3 || p(I64 *)[-1]>=0 || q[0] || q[130999] ||
      MemoryHeap(p)!=task->data_heap || MemoryHeap(q)!=task->code_heap ||
      MemorySize2(p)!=MemorySize(p)+offset(CMemUsed.start)) KernelStop;
  p[0]=71; p[2047]=83; q[0]=97; q[130999]=109;
  MemoryFree(q);
  if(probe_pool.owned_count!=1 || p[0]!=71 || p[2047]!=83) KernelStop;
  MemoryFree(p);
  p=MemoryCAligned(2048,256,0,5);
  if((p+0)(U64)%256!=5 || p[0] || p[2047]) KernelStop;
  MemoryFree(p); MemoryFree(0);
  if(MemorySize(0) || MemorySize2(0) || MemoryHeap(0)) KernelStop;
  if(probe_pool.owned_count || probe_pool.retained || probe_pool.used_u8s ||
      probe_pool.heap->used!=before || probe_pool.heap->allocations!=allocations ||
      !I386HeapValid(probe_pool.heap)) KernelStop;
  //Prove full teardown, then restore the original control bytes at the same
  //address. Its self-linked sentinels still name the original live control.
  if(!I386MemHeapDestroy(&state->control)) KernelStop;
  probe_pool.reclaim=0;
  if(!I386MemBackingDestroy(&probe_pool)) KernelStop;
  for(i=0;i<sizeof(CHeapCtrl);i++) (&state->control)(U8 *)[i]=(&saved_control)(U8 *)[i];
  for(i=0;i<sizeof(CI386BackingPool);i++)
    if((&memory_pool)(U8 *)[i]!=(&root_before)(U8 *)[i]) KernelStop;
  if(I386TaskHeapsValid(task)!=state || !I386MemBackingValid(&memory_pool) ||
      memory_pool.heap->used!=before || memory_pool.heap->allocations!=allocations) KernelStop;
  KernelLog("MEMORY PROBE ISOLATED "); KernelHex(phase); KernelLog("\n");
  I386IrqRestore(flags);
  KernelLog("MEMORY PROBE "); KernelHex(phase); KernelLog("\n");
}
#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/MemoryBacking.HC"
#include "/Kernel/I386/TaskHeaps.HC"
#include "/Kernel/I386/MemoryPublic.HC"

#include "/Kernel/I386/HashPublic.HC"
#include "/Kernel/I386/HashPublicProbe.HC"

//Module-local aliases apply only to this final shared include.
#define Fs I386TaskSelf
#define LBEqu MemoryLockedBitEqu
#include "/Kernel/TaskDelayCore.HC"

Bool MemoryCoreYield(CI386Scheduler *scheduler) { return I386SchedYield(scheduler); }
#include "/Kernel/I386/TaskRuntimeCore.HC"
#include "/Kernel/I386/TaskRuntimePublic.HC"

#include "/Kernel/I386/MessagePosting.HC"

#include "/Kernel/I386/JobDispatch.HC"

#include "/Kernel/I386/MessageScan.HC"

#include "/Kernel/I386/TaskKill.HC"
