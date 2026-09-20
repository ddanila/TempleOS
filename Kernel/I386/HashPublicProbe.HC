public _intern 0x15 CTask *Fs();
#include "/Kernel/I386/HashTableCheck.HC"
#include "/Kernel/I386/DefineListCheck.HC"
I64 memory_hash_copies;
U8 *MemoryHashFailCopy(U8 *str,CTask *task)
{
  if(++memory_hash_copies==2) throw('OutMem',TRUE);
  return MemoryStrNew(str,task);
}
I64 memory_define_fail_at,memory_define_allocations;
U8 *MemoryDefineFailAlloc(I64 size,CTask *task)
{
  if(++memory_define_allocations==memory_define_fail_at) throw('OutMem',TRUE);
  return MemoryCAlloc(size,task);
}
U8 *MemoryDefineFailCopy(U8 *str,CTask *task)
{
  I64 size=0;
  U8 *copy;
  while(str[size]) size++;
  copy=MemoryDefineFailAlloc(size+1,task);
  MemoryStrCopy(copy,str);
  return copy;
}
U8 *MemoryDefineFailSource(U8 *) { return MemoryDefineFailCopy("AD:0x1234",0); }
U0 MemoryDefineFailureProbe()
{
  CI386Task *task=I386TaskSelf;
  CHashTable *table=MemoryHashTableNew(1);
  I64 i;
  Bool caught;
  U32 flags=GetRFlags;
  for(i=1;i<=5;i++) {
    caught=FALSE; memory_define_allocations=0; memory_define_fail_at=i;
    try {
      DefineLstLoadCore("FailedList","first\0@alias\0second\0",table,0,
        &MemoryDefineFailAlloc,&MemoryDefineFailCopy,&MemoryDefineFailSource,
        &MemoryHashDel,&HashAdd);
      KernelStop;
    } catch {
      if(task->except_ch!='OutMem') KernelStop;
      task->catch_except=TRUE; caught=TRUE;
    }
    if(!caught || memory_define_allocations!=i || table->body[0] ||
        (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  }
  MemoryHashTableDel(table);
}
U0 MemoryHashProbe()
{
  CI386Task *task=I386TaskSelf;
  CHashTable *table;
  Bool caught=FALSE;
  U32 flags=GetRFlags;
  if(HashTableCheck(&MemoryHashTableNew,&MemoryHashTableDel,&MemoryHashLstAdd,
      &HashFind,&MemoryHeap)!=10) KernelStop;
  try { MemoryHashTableNew(0x400000); KernelStop; }
  catch {
    if(task->except_ch!='OutMem') KernelStop;
    task->catch_except=TRUE; caught=TRUE;
  }
  if(!caught || (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  table=MemoryHashTableNew(8); caught=FALSE; memory_hash_copies=0;
  try {
    HashLstAddCore("first\0second\0",HTT_KEYWORD,table,&MemoryCAlloc,
      &MemoryHashFailCopy,&MemoryFree,&HashAdd);
    KernelStop;
  } catch {
    if(task->except_ch!='OutMem') KernelStop;
    task->catch_except=TRUE; caught=TRUE;
  }
  if(!caught || memory_hash_copies!=2 || !HashFind("first",table,HTT_KEYWORD) ||
      HashFind("second",table,HTT_KEYWORD) || (GetRFlags&0x200)!=(flags&0x200)) KernelStop;
  MemoryHashTableDel(table);
  KernelLog("PUBLIC HASH TABLES OK\n");
  if(DefineListCheck(&MemoryDefineLstLoad,&MemoryHashDefineLstAdd,
      &MemoryHashTableNew,&MemoryHashTableDel,&MemoryHashDel,&HashFind)!=6) KernelStop;
  MemoryDefineFailureProbe;
  KernelLog("PUBLIC DEFINE LIST OK\n");
}
