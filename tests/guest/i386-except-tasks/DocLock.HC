#include "/Kernel/I386/DocLock.HC"
U0 I386DocBreakPoll() { I386TaskBreakPoll; }
CDoc lock_doc;
U32 doc_stage,doc_caught;
U0 DocLockWorker(I64 scenario)
{
  CI386Task *task=I386TaskSelf;
  try {
    doc_stage=1;
    if(!I386DocLock(&lock_doc)) failures++;
    doc_stage=2;
    if(I386DocLock(&lock_doc) || lock_doc.owning_task!=task ||
        !(task->task_flags&(1<<TASKf_BREAK_LOCKED))) failures++;
    I386SchedYield(&scheduler);
    I386DocUnlock(&lock_doc);
    failures++; //The owner must deliver its pending break after releasing the doc.
  } catch {
    if(task->except_ch!='Break' || task->task_flags&(1<<TASKf_PENDING_BREAK|1<<TASKf_BREAK_LOCKED) ||
        (GetRFlags&0x200)) failures++;
    if(scenario==0 && (doc_stage!=1 || lock_doc.owning_task!=&root ||
        !Bt(&lock_doc.locked_flags,DOClf_LOCKED))) failures++;
    if(scenario==1 && (doc_stage!=2 || lock_doc.owning_task ||
        Bt(&lock_doc.locked_flags,DOClf_LOCKED))) failures++;
    task->catch_except=TRUE; doc_caught++;
  }
}
I64 DocLockTest()
{
  I64 scenario;
  CI386Task *task;
  for(scenario=0;scenario<2;scenario++) {
    doc_stage=doc_caught=0;
    if(!I386DocLock(&lock_doc) || I386DocLock(&lock_doc)) return 70;
    workers[0]=I386TaskSpawn(&scheduler,&heap,8192,&DocLockWorker,scenario,0x18,0x20,4096);
    if(!workers[0]) return 71;
    task=&workers[0]->task;
    if(!I386SchedYield(&scheduler) || doc_stage!=1 || task->finished) return 72;
    if(scenario==0) {
      if(!I386TaskBreakRequest(task) || !I386SchedYield(&scheduler) ||
          doc_caught!=1 || !task->finished || !I386DocUnlock(&lock_doc)) return 73;
    } else {
      if(!I386DocUnlock(&lock_doc) || !I386SchedYield(&scheduler) || doc_stage!=2 ||
          I386DocUnlock(&lock_doc) || lock_doc.owning_task!=task) return 74;
      if(!I386TaskBreakRequest(task) || !I386SchedYield(&scheduler) ||
          doc_caught!=1 || !task->finished) return 75;
    }
    if(failures || !I386TaskDestroy(workers[0]) || heap.used || heap.allocations ||
        !I386HeapValid(&heap) || I386DocUnlock(&lock_doc) ||
        root.task_flags&(1<<TASKf_BREAK_LOCKED|1<<TASKf_PENDING_BREAK)) return 76;
  }
  //A preexisting break lock belongs to the caller, not the document.
  if(!I386TaskBreakLock(&root) || !I386DocLock(&lock_doc) ||
      Bt(&lock_doc.flags,DOCf_BREAK_UNLOCKED) || !I386DocUnlock(&lock_doc) ||
      !(root.task_flags&(1<<TASKf_BREAK_LOCKED)) || !I386TaskBreakUnlock(&root)) return 77;
  return 0;
}
