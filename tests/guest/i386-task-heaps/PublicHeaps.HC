#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/MemoryBacking.HC"
#include "/Kernel/I386/TaskHeaps.HC"
#include "/Kernel/I386/TaskStorage.HC"
CI386BackingPool task_pool;
CI386Heap task_control_storage,task_backing_storage;
CI386OwnedTask *heap_workers[2];
U8 *heap_payloads[2];
U32 heap_stages[2],heap_file_failures;
U32 heap_reclaims;
CI386Task *heap_reclaim_target;
extern U0 PublicHeapReclaim(CI386PublicPool *pool);
extern U0 PublicHeapWorker(I64 id);
extern U0 PublicHeapCleanup(CI386Task *task);
extern Bool PublicHeapCompilerCleanup(CI386Task *task);
extern Bool PublicHeapFileDestroy(CI386Task *task);
extern Bool PublicHeapSymbolDestroy(CI386Task *task);
extern Bool PublicHeapCloneFailure(CI386Task *source,CI386Task *target,CI386Heap *heap);
Bool CodeProviderTest(CI386TaskHeaps *state)
{
  CHeapCtrl *hc=&state->control;
  CI386TaskHeaps invalid;
  CI386TaskStorage *retained;
  U8 *p,*q;
  I64 mode,i,used,pages;
  U32 flags=GetRFlags,expected;
  invalid.task=0;
  if(!state->code_allocate || !state->code_release || !state->code_capacity) return FALSE;
  for(mode=0;mode<2;mode++) {
    expected=(flags&~0x200)|(mode<<9); SetRFlags(expected);
    p=(*state->code_allocate)(state,64); q=(*state->code_allocate)(state,17);
    if(!p || !q || (*state->code_capacity)(state,p)<64 ||
        (p-offset(CMemUsed.start))(CMemUsed *)->hc!=hc) return FALSE;
    p[0]=37; p[63]=83; used=hc->used_u8s; pages=hc->alloced_u8s;
    if(I386MemHeapTrim(hc) || hc->used_u8s!=used || hc->alloced_u8s!=pages ||
        (*state->code_capacity)(&invalid,p)!=-1 || (*state->code_release)(&invalid,p)) return FALSE;
    hc->locked_flags=1;
    if((*state->code_allocate)(state,8) || (*state->code_release)(state,q) ||
        I386MemHeapTrim(hc) || hc->used_u8s!=used) return FALSE;
    hc->locked_flags=0;
    if(!(*state->code_release)(state,q) || hc->alloced_u8s!=pages || p[0]!=37 || p[63]!=83 ||
        !(*state->code_release)(state,p) || hc->used_u8s || hc->alloced_u8s ||
        hc->hc_signature!=HEAP_CTRL_SIGNATURE_VAL || hc->mem_task!=state->task ||
        hc->malloc_free_lst || hc->last_mergable || hc->next_mem_blk!=&hc->next_mem_blk ||
        hc->last_mem_blk!=&hc->next_mem_blk) return FALSE;
    for(i=0;i<MEM_HEAP_HASH_SIZE/sizeof(U8 *);i++) if(hc->heap_hash[i]) return FALSE;
    task_pool.locked_flags=1;
    if(I386MemHeapTrim(hc)) return FALSE;
    task_pool.locked_flags=0;
    if(!I386MemHeapTrim(hc) || I386MemHeapTrim(0) ||
        I386MemBackingTrim(&task_pool)<=0 || task_backing_storage.used || task_pool.used_u8s ||
        (GetRFlags&0x200)!=(expected&0x200)) return FALSE;
    //Reuse the same control after its cache was returned, including a large buffer.
    p=(*state->code_allocate)(state,4096);
    if(!p) return FALSE;
    retained=I386HeapAlloc(&task_control_storage,sizeof(CI386TaskStorage),TRUE);
    if(!retained) return FALSE;
    retained->count=1; retained->allocations[0].allocation=p; retained->allocations[0].owner=state;
    hc->locked_flags=1;
    if(I386TaskStorageRelease(&task_control_storage,retained) ||
        I386HeapSize(&task_control_storage,retained)!=sizeof(CI386TaskStorage) ||
        (*state->code_capacity)(state,p)<4096) return FALSE;
    hc->locked_flags=0; task_pool.locked_flags=1;
    if((*state->code_release)(state,p) || I386TaskStorageRelease(&task_control_storage,retained)) return FALSE;
    task_pool.locked_flags=0;
    if(!I386TaskStorageRelease(&task_control_storage,retained) ||
        I386MemBackingTrim(&task_pool)<=0 || task_backing_storage.used) return FALSE;
  }
  SetRFlags(flags); return TRUE;
}
I64 PublicTaskHeapTest()
{
  CI386Heap heap;
  CI386Task *root=scheduler.root,*worker;
  CI386TaskHeaps *state;
  U8 *root_payload;
  I64 i,j,cycle,before,root_pages,retained,reclaims;
  U32 flags=GetRFlags;
  if(!I386HeapInit(&heap,0x40000,32768) ||
      !I386HeapInit(&task_control_storage,0x48000,32768) ||
      !I386HeapInit(&task_backing_storage,0x50000,0x30000) ||
      !I386MemBackingInit(&task_pool,&task_backing_storage,8192) ||
      !I386TaskHeapsInit(root,&task_control_storage,&task_pool) ||
      I386TaskHeapsInit(root,&task_control_storage,&task_pool)) return 101;
  state=root->heap_state;
  if(!CodeProviderTest(state)) return 120;
  task_pool.reclaim=&PublicHeapReclaim;
  if(I386MemPoolEmpty(&task_pool) || I386MemBackingDestroy(&task_pool) ||
      !I386MemBackingValid(&task_pool)) return 119;
  if(root->code_heap!=root->data_heap || root->data_heap->mem_task!=root ||
      task_control_storage.allocations!=1 || state->parent) return 102;
  root_payload=I386MemAlloc(root->data_heap,64);
  if(!root_payload) return 103;
  root_payload[0]=0xA7; root_pages=task_pool.used_u8s;
  //Construction failures must release controls, pages and the parent's pin.
  before=heap.used;
  if(I386TaskSpawn(&scheduler,&heap,8192,&PublicHeapWorker,0,0x18,0x20,24) ||
      heap.used!=before || root->lifetime_refs || state->children ||
      task_pool.used_u8s!=root_pages) return 104;
  root->file_state=root; root->file_clone=&PublicHeapCloneFailure;
  root->file_destroy=&PublicHeapFileDestroy;
  if(I386TaskSpawn(&scheduler,&heap,8192,&PublicHeapWorker,0) ||
      heap.used!=before || root->lifetime_refs || state->children ||
      task_pool.used_u8s!=root_pages || heap_file_failures!=1 || heap_reclaims!=1) return 105;
  root->file_state=0; root->file_clone=0; root->file_destroy=0;
  //Overflow and partial hook sets are rejected without publishing a task.
  root->lifetime_refs=0xFFFFFFFF;
  if(I386TaskSpawn(&scheduler,&heap,8192,&PublicHeapWorker,0) || heap.used) return 106;
  root->lifetime_refs=0;
  root->heap_clone=0;
  if(I386TaskSpawn(&scheduler,&heap,8192,&PublicHeapWorker,0) || heap.used) return 107;
  root->heap_clone=&I386TaskHeapsClone;
  for(cycle=0;cycle<4;cycle++) {
    for(i=0;i<2;i++) {
      heap_stages[i]=0; heap_payloads[i]=0;
      heap_workers[i]=I386TaskSpawn(&scheduler,&heap,8192,&PublicHeapWorker,i,0x18,0x20,4096);
      if(!heap_workers[i]) return 108;
      worker=&heap_workers[i]->task;
      if(worker->code_heap!=worker->data_heap || worker->data_heap==root->data_heap ||
          worker->data_heap->mem_task!=worker || !worker->heap_state ||
          I386TaskHeapsDestroy(worker)) return 109;
    }
    if(root->lifetime_refs!=2 || state->children!=2 || I386TaskHeapsDestroy(root)) return 110;
    SetRFlags(flags|0x200);
    for(j=0;j<4;j++) if(!I386SchedYield(&scheduler) || !(GetRFlags&0x200)) return 111;
    I386IrqSave;
    if(errors || root_payload[0]!=0xA7) return 112;
    for(i=0;i<2;i++) {
      worker=&heap_workers[i]->task;
      if(!worker->finished || heap_stages[i]!=3 || !worker->data_heap ||
          I386MemSize(heap_payloads[i])<1024 || heap_payloads[i][1023]!=i+71) return 113;
      //Reap must defer heap destruction while file/symbol cleanup is pending.
      retained=task_pool.retained; reclaims=heap_reclaims;
      heap_reclaim_target=worker;
      if(I386TaskHeapsDestroy(worker)) return 114;
      worker->data_heap->locked_flags=1;
      if(I386TaskDestroy(heap_workers[i]) || heap_stages[i]!=5 ||
          !worker->heap_state || !worker->data_heap || !worker->owner ||
          heap_reclaims!=reclaims || task_pool.retained!=retained) return 115;
      worker->data_heap->locked_flags=0;
      if(!I386TaskDestroy(heap_workers[i]) || root_payload[0]!=0xA7 ||
          heap_reclaims!=reclaims+1 || task_pool.retained>=retained) return 116;
    }
    if(errors || root->lifetime_refs || state->children || heap.used || heap.allocations ||
        !I386HeapValid(&heap) || task_pool.used_u8s!=root_pages) return 117;
  }
  //Root detach is an explicit provider shutdown, not normal task exit.
  heap_reclaim_target=root;
  if(!I386TaskHeapsDestroy(root) || task_pool.used_u8s || task_control_storage.used ||
      task_control_storage.allocations || root->data_heap || root->code_heap || root->heap_state ||
      root->heap_clone || root->heap_destroy || I386TaskHeapsDestroy(root)) return 118;
  if(errors || task_pool.retained || task_pool.owned_count || task_backing_storage.used ||
      task_backing_storage.allocations || heap_reclaims!=10) return 120;
  task_pool.reclaim=0;
  if(!I386MemBackingDestroy(&task_pool)) return 121;
  SetRFlags(flags);
  return 0;
}
U0 PublicHeapReclaim(CI386PublicPool *pool)
{
  CI386Task *task=heap_reclaim_target;
  CI386TaskHeaps *parent=scheduler.root->heap_state;
  if(pool!=&task_pool || GetRFlags&0x200 || pool->locked_flags || pool->growing ||
      !task || task->code_heap || task->data_heap || task->heap_state ||
      task->heap_clone || task->heap_destroy ||
      task!=scheduler.root && (!parent || scheduler.root->lifetime_refs!=parent->children) ||
      I386MemBackingTrim(&task_pool)<0) errors++;
  heap_reclaim_target=0;
  heap_reclaims++;
}
Bool PublicHeapCloneFailure(CI386Task *source,CI386Task *target,CI386Heap *heap)
{
  heap_reclaim_target=target;
  U8 *p=I386MemAlloc(target->data_heap,2048);
  if(!p || target->owner || !target->heap_state || !source->lifetime_refs) errors++;
  else p[0]=0x55;
  heap_file_failures++;
  return FALSE;
}
U0 PublicHeapWorker(I64 id)
{
  CI386Task *task=I386TaskSelf;
  U8 *p=I386MemAlloc(task->data_heap,1024),*q=I386MemAlloc(task->code_heap,31);
  if(!p || !q) { errors++; return; }
  SetRFlags(GetRFlags|0x200);
  heap_payloads[id]=p; p[0]=id+41; p[1023]=id+71; q[0]=91;
  if(!I386MemFree(q) || !I386SchedSetCleanup(&scheduler,&PublicHeapCleanup)) errors++;
  task->compiler_cleanup=&PublicHeapCompilerCleanup; task->active_controls=1;
  //Synthetic dependency destructors verify the scheduler's actual ordering.
  task->file_state=task; task->file_clone=&PublicHeapCloneFailure;
  task->file_destroy=&PublicHeapFileDestroy;
  task->hash_table=task; task->symbol_state=task; task->symbol_clone=&PublicHeapCloneFailure;
  task->symbol_destroy=&PublicHeapSymbolDestroy;
  heap_stages[id]=1;
  if(!I386SchedYield(&scheduler) || p[0]!=id+41 || p[1023]!=id+71 ||
      I386TaskHeapsDestroy(task)) errors++;
}
U0 PublicHeapCleanup(CI386Task *task)
{
  I64 id=0;
  if(task==&heap_workers[1]->task) id=1;
  if(task!=I386TaskSelf || heap_stages[id]!=1 || !(GetRFlags&0x200) ||
      I386TaskHeapsDestroy(task) || I386MemSize(heap_payloads[id])<1024) errors++;
  heap_stages[id]=2;
  if(!I386SchedYield(&scheduler) || heap_payloads[id][0]!=id+41) errors++;
}
Bool PublicHeapCompilerCleanup(CI386Task *task)
{
  I64 id=0;
  U8 *p=I386MemAlloc(task->data_heap,64);
  if(task==&heap_workers[1]->task) id=1;
  if(!p || heap_stages[id]!=2 || !(GetRFlags&0x200) ||
      I386TaskHeapsDestroy(task) || !I386MemFree(p)) errors++;
  task->active_controls=0; task->compiler_cleanup=0;
  heap_stages[id]=3;
  return TRUE;
}
Bool PublicHeapFileDestroy(CI386Task *task)
{
  I64 id=0;
  if(task==&heap_workers[1]->task) id=1;
  if(heap_stages[id]!=3 || !task->finished || !task->hash_table ||
      !task->data_heap || heap_payloads[id][0]!=id+41) errors++;
  task->file_state=0; task->file_clone=0; task->file_destroy=0;
  heap_stages[id]=4;
  return TRUE;
}
Bool PublicHeapSymbolDestroy(CI386Task *task)
{
  I64 id=0;
  if(task==&heap_workers[1]->task) id=1;
  if(heap_stages[id]!=4 || task->file_state || !task->data_heap ||
      heap_payloads[id][1023]!=id+71) errors++;
  task->hash_table=0; task->symbol_state=0; task->symbol_clone=0; task->symbol_destroy=0;
  heap_stages[id]=5;
  return TRUE;
}
