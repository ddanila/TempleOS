#ifdef I386_TASK_RETAINED_BUILD
#define I386_TASK_IMPLEMENTATION_ASM 0
#else
#ifdef I386_TASK_NATIVE_BUILD
#define I386_TASK_IMPLEMENTATION_ASM 1
#else
#define I386_TASK_IMPLEMENTATION_ASM 0
#endif
#endif
#include "/Kernel/I386/Task.HH"
#include "/Kernel/I386/Cpu.HH"
#if I386_TASK_IMPLEMENTATION_ASM
#assert offset(CI386OwnedTask.task)==0
#endif
//Link Context, Scheduler, Heap and Cpu once. Requires working Fs task binding.
public U0 I386TaskReturn()
{//Normal entry return retires the current task; another task destroys its stack.
  I386SchedFinish(I386TaskSelf->owner);
  while (1) {}
}
public CI386OwnedTask *I386TaskCreateFrom(CI386Scheduler *s,CI386Heap *heap,
  CI386Task *parent,I64 stack_size,U0 (*entry)(I64 arg),I64 arg,
  U16 fs=0x18,U16 gs=0x20,I64 private_size=0,Bool queued=FALSE)
{//NULL-returning bootstrap API, not the full public Spawn/OutMem contract.
  CI386OwnedTask *owned;
  CI386Task *creator[1];
  CI386Heap *file_heap;
  I64 header=(sizeof(CI386OwnedTask)+offset(CTaskStk.stk_base)+7)&~7,total;
  U32 flags,invalid[1];
  creator[0]=0;
#if I386_TASK_IMPLEMENTATION_ASM
  //Validate native pointer fields directly, retaining the C checks for other targets.
  invalid[0]=0;
  asm {
    PUSH EAX
    PUSH ESI
    PUSH EDI
    MOV ESI,U32 &s[EBP]
    TEST ESI,ESI
    JZ I32 @@10
    MOV EAX,U32 CI386Scheduler.root[ESI]
    TEST EAX,EAX
    JZ I32 @@10
    MOV EAX,U32 CI386Scheduler.bind[ESI]
    TEST EAX,EAX
    JZ I32 @@10
    MOV EDI,U32 &parent[EBP]
    TEST EDI,EDI
    JZ I32 @@10
    CMP ESI,U32 CI386Task.owner[EDI]
    JNZ I32 @@10
    CMP EDI,U32 CTask.addr[EDI]
    JNZ I32 @@10
    MOV EAX,U32 CI386Task.finished[EDI]
    TEST EAX,EAX
    JNZ I32 @@10
    MOV EAX,U32 CI386Task.finishing[EDI]
    TEST EAX,EAX
    JZ I32 @@11
@@10:
    MOV EAX,1
    MOV U32 &invalid[EBP],EAX
@@11:
    POP EDI
    POP ESI
    POP EAX
  }
  if(invalid[0]) return 0;
#else
  if (!s || !s->root || !s->bind || !parent || parent->owner!=s ||
      parent->addr!=parent || parent->finished || parent->finishing) return 0;
#endif
#if I386_TASK_IMPLEMENTATION_ASM
  invalid[0]=0;
  asm {
    PUSH EAX
    PUSH ECX
    PUSH EDX
    PUSH EDI
    MOV EAX,U32 &heap[EBP]
    TEST EAX,EAX
    JZ I32 @@60
    MOV EAX,U32 &entry[EBP]
    TEST EAX,EAX
    JZ I32 @@60
    LEA ECX,U32 &stack_size[EBP]
    ADD ECX,4
    MOV ECX,U32 [ECX]
    TEST ECX,ECX
    JNZ I32 @@60
    MOV EAX,U32 &stack_size[EBP]
    CMP EAX,256
    JB I32 @@60
    TEST EAX,7
    JNZ I32 @@60
    MOV ECX,U32 &header[EBP]
    MOV EDX,0xFFFFFFFF
    SUB EDX,ECX
    CMP EAX,EDX
    JA I32 @@60
    SUB EDX,EAX
    LEA ECX,U32 &private_size[EBP]
    ADD ECX,4
    MOV ECX,U32 [ECX]
    TEST ECX,ECX
    JNZ I32 @@60
    MOV EDI,U32 &private_size[EBP]
    MOV ECX,EDI
    AND ECX,7
    TEST ECX,ECX
    JNZ I32 @@60
    TEST EDI,EDI
    JZ I32 @@61
    CMP EDI,24
    JB I32 @@60
@@61:
    CMP EDI,EDX
    JA I32 @@60
    JMP I32 @@62
@@60:
    MOV EAX,1
    MOV U32 &invalid[EBP],EAX
@@62:
    POP EDI
    POP EDX
    POP ECX
    POP EAX
  }
  if(invalid[0]) return 0;
#else
  if (!heap || !entry || stack_size<256 ||
      stack_size&7 || stack_size>0xFFFFFFFF-header) return 0;
  if (private_size<0 || private_size&7 || (private_size && private_size<24) ||
      private_size>0xFFFFFFFF-header-stack_size) return 0;
#endif
  total=header+stack_size+private_size;
  flags=I386IrqSave;
  if(parent!=s->current) {
    creator[0]=s->current;
#if I386_TASK_IMPLEMENTATION_ASM
    invalid[0]=0;
    asm {
      PUSH EAX
      PUSH ECX
      PUSH ESI
      PUSH EDI
      MOV ESI,U32 &creator[EBP]
      TEST ESI,ESI
      JZ I32 @@20
      LEA EDI,U32 CI386Task.owner[ESI]
      MOV EAX,U32 [EDI]
      CMP EAX,U32 &s[EBP]
      JNZ I32 @@20
      MOV EAX,U32 CI386Task.finished[ESI]
      TEST EAX,EAX
      JNZ I32 @@20
      MOV EAX,U32 CI386Task.finishing[ESI]
      TEST EAX,EAX
      JNZ I32 @@20
      MOV EAX,U32 CI386Task.lifetime_refs[ESI]
      CMP EAX,0xFFFFFFFF
      JNZ I32 @@21
@@20:
      MOV EAX,1
      MOV U32 &invalid[EBP],EAX
@@21:
      POP EDI
      POP ESI
      POP ECX
      POP EAX
    }
#else
    invalid[0]=!creator[0] || creator[0]->owner!=s || creator[0]->finished ||
      creator[0]->finishing || creator[0]->lifetime_refs==0xFFFFFFFF;
#endif
    if(invalid[0]) { I386IrqRestore(flags); return 0; }
  }
  owned=I386HeapAlloc(heap,total,TRUE);
  if (!owned) { I386IrqRestore(flags); return 0; }
  owned->heap=heap; owned->allocation_size=total; owned->signature=0x54323349;
  //The public descriptor directly precedes its eight-byte-aligned stack.
  owned->task.stk=(owned+0)(U8 *)+header-offset(CTaskStk.stk_base);
  owned->task.stk->stk_size=stack_size;
  if (private_size) {
    if (!I386HeapInit(&owned->local_heap,(owned+0)(U8 *)+header+stack_size,private_size)) {
      I386HeapFree(heap,owned); I386IrqRestore(flags); return 0;
    }
    owned->task.memory=&owned->local_heap;
  }
  if (!I386ContextInit(&owned->task.context,&owned->task.stk->stk_base,owned->task.stk->stk_size,
      entry,arg,&I386TaskReturn,fs,gs)) goto spawn_fail;
  file_heap=heap; if(owned->task.memory) file_heap=owned->task.memory;
  if(I386TaskHeapHooks(parent)) {
    if(I386TaskHeapHooks(parent)!=31 ||
        !(*parent->heap_clone)(parent,&owned->task,file_heap)) goto spawn_fail;
  }
  if(parent->file_state || parent->file_clone || parent->file_destroy) {
    if(!parent->file_state || !parent->file_clone || !parent->file_destroy ||
        !(*parent->file_clone)(parent,&owned->task,file_heap)) goto spawn_fail;
  }
  if(parent->hash_table || parent->symbol_state || parent->symbol_clone || parent->symbol_destroy) {
    if(!parent->hash_table || !parent->symbol_state || !parent->symbol_clone || !parent->symbol_destroy ||
        !(*parent->symbol_clone)(parent,&owned->task,file_heap)) goto spawn_fail;
  }
  //Inherited state belongs to the parent; entry code can belong to the creator.
  owned->creator=creator[0];
  if(creator[0]) creator[0]->lifetime_refs++;
  if(queued) {
    if(!I386SchedAdd(s,&owned->task)) goto spawn_fail;
  } else if(!I386SchedPrepare(s,&owned->task)) goto spawn_fail;
  I386IrqRestore(flags);
  return owned;
spawn_fail:
  if(owned->task.symbol_state && (!owned->task.symbol_destroy || !(*owned->task.symbol_destroy)(&owned->task))) {
    I386IrqRestore(flags); return 0;
  }
  if(owned->task.file_state && (!owned->task.file_destroy || !(*owned->task.file_destroy)(&owned->task))) {
    I386IrqRestore(flags); return 0;
  }
  if(owned->task.heap_state && (!owned->task.heap_destroy || !(*owned->task.heap_destroy)(&owned->task))) {
    I386IrqRestore(flags); return 0;
  }
  if(owned->creator) owned->creator->lifetime_refs--;
  I386HeapFree(heap,owned);
  I386IrqRestore(flags);
  return 0;
}
public CI386OwnedTask *I386TaskSpawnFrom(CI386Scheduler *s,CI386Heap *heap,
  CI386Task *parent,I64 stack_size,U0 (*entry)(I64 arg),I64 arg,
  U16 fs=0x18,U16 gs=0x20,I64 private_size=0)
{//Keep the existing immediate-spawn ABI while sharing the owned constructor.
  return I386TaskCreateFrom(s,heap,parent,stack_size,entry,arg,fs,gs,private_size,TRUE);
}
public CI386OwnedTask *I386TaskSpawn(CI386Scheduler *s,CI386Heap *heap,
  I64 stack_size,U0 (*entry)(I64 arg),I64 arg,U16 fs=0x18,U16 gs=0x20,I64 private_size=0)
{
  if(!s) return 0;
  return I386TaskSpawnFrom(s,heap,s->current,stack_size,entry,arg,fs,gs,private_size);
}
public Bool I386TaskDestroy(CI386OwnedTask *owned)
{//Readable live owned record required. Never destroy from its own stack.
  U32 flags=I386IrqSave;
  CI386Heap *heap;
  CI386Task *creator[1];
  U32 invalid[1];
  Bool result;
#if I386_TASK_IMPLEMENTATION_ASM
  invalid[0]=0;
  asm {
    PUSH EAX
    PUSH ESI
    MOV ESI,U32 &owned[EBP]
    TEST ESI,ESI
    JZ I32 @@40
    MOV EAX,U32 CI386OwnedTask.signature[ESI]
    CMP EAX,0x54323349
    JNZ I32 @@40
    MOV EAX,U32 CI386Task.owner[ESI]
    TEST EAX,EAX
    JZ I32 @@40
    MOV EAX,U32 CI386Task.finished[ESI]
    TEST EAX,EAX
    JZ I32 @@40
    MOV EAX,U32 CI386Task.owner[ESI]
    CMP ESI,U32 CI386Scheduler.current[EAX]
    JNZ I32 @@41
@@40:
    MOV EAX,1
    MOV U32 &invalid[EBP],EAX
@@41:
    POP ESI
    POP EAX
  }
  if(invalid[0]) { I386IrqRestore(flags); return FALSE; }
#else
  if (!owned || owned->signature!=0x54323349 || !owned->task.owner ||
      !owned->task.finished || owned->task.owner->current==&owned->task) {
    I386IrqRestore(flags); return FALSE;
  }
#endif
  heap=owned->heap;
  creator[0]=owned->creator;
  if(creator[0]) {
#if I386_TASK_IMPLEMENTATION_ASM
    invalid[0]=0;
    asm {
      PUSH EAX
      PUSH ECX
      PUSH EDX
      PUSH ESI
      PUSH EDI
      MOV ESI,U32 &creator[EBP]
      MOV EDI,U32 &owned[EBP]
      //Native owner pointers occupy one U32; the next field is finished.
      LEA ECX,U32 CI386Task.owner[ESI]
      LEA EDX,U32 CI386Task.owner[EDI]
      MOV EAX,U32 [ECX]
      CMP EAX,U32 [EDX]
      JNZ I32 @@30
      MOV EAX,U32 CI386Task.lifetime_refs[ESI]
      TEST EAX,EAX
      JNZ I32 @@31
@@30:
      MOV EAX,1
      MOV U32 &invalid[EBP],EAX
@@31:
      POP EDI
      POP ESI
      POP EDX
      POP ECX
      POP EAX
    }
#else
    invalid[0]=creator[0]->owner!=owned->task.owner || !creator[0]->lifetime_refs;
#endif
    if(invalid[0]) { I386IrqRestore(flags); return FALSE; }
  }
  if (I386HeapSize(heap,owned)!=owned->allocation_size ||
      !I386SchedReap(owned->task.owner,&owned->task)) {
    I386IrqRestore(flags); return FALSE;
  }
  result=I386HeapFree(heap,owned);
  if(result && creator[0]) creator[0]->lifetime_refs--;
  I386IrqRestore(flags);
  return result;
}
