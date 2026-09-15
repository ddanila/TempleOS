#include "/Kernel/I386/Memory.HC"
#include "/Kernel/I386/TaskHeaps.HC"
CI386PublicPool task_pool;
CI386Heap task_control_storage;
CI386OwnedTask *heap_workers[2];
U8 *heap_payloads[2];
U32 heap_stages[2],heap_file_failures;
extern U0 PublicHeapWorker(I64 id);
extern U0 PublicHeapCleanup(CI386Task *task);
extern Bool PublicHeapCompilerCleanup(CI386Task *task);
extern Bool PublicHeapFileDestroy(CI386Task *task);
extern Bool PublicHeapSymbolDestroy(CI386Task *task);
extern Bool PublicHeapCloneFailure(CI386Task *source,CI386Task *target,CI386Heap *heap);
I64 PublicTaskHeapTest()
{
  CI386Heap heap;
  CI386Task *root=scheduler.root,*worker;
  CI386TaskHeaps *state;
  U8 *root_payload;
  I64 i,j,cycle,before,root_pages;
  U32 flags=GetRFlags;
  if(!I386HeapInit(&heap,0x40000,32768) ||
      !I386HeapInit(&task_control_storage,0x48000,32768) ||
      !I386MemPoolInit(&task_pool,0x50000,0x30000) ||
      !I386TaskHeapsInit(root,&task_control_storage,&task_pool) ||
      I386TaskHeapsInit(root,&task_control_storage,&task_pool)) return 101;
  state=root->heap_state;
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
      task_pool.used_u8s!=root_pages || heap_file_failures!=1) return 105;
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
      if(I386TaskHeapsDestroy(worker)) return 114;
      worker->data_heap->locked_flags=1;
      if(I386TaskDestroy(heap_workers[i]) || heap_stages[i]!=5 ||
          !worker->heap_state || !worker->data_heap || !worker->owner) return 115;
      worker->data_heap->locked_flags=0;
      if(!I386TaskDestroy(heap_workers[i]) || root_payload[0]!=0xA7) return 116;
    }
    if(errors || root->lifetime_refs || state->children || heap.used || heap.allocations ||
        !I386HeapValid(&heap) || task_pool.used_u8s!=root_pages) return 117;
  }
  //Root detach is an explicit provider shutdown, not normal task exit.
  if(!I386TaskHeapsDestroy(root) || task_pool.used_u8s || task_control_storage.used ||
      task_control_storage.allocations || root->data_heap || root->code_heap || root->heap_state ||
      root->heap_clone || root->heap_destroy || I386TaskHeapsDestroy(root)) return 118;
  SetRFlags(flags);
  return 0;
}
Bool PublicHeapCloneFailure(CI386Task *source,CI386Task *target,CI386Heap *heap)
{
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
