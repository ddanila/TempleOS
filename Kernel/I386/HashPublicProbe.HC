public _intern 0x15 CTask *Fs();
#include "/Kernel/I386/HashTableCheck.HC"
I64 memory_hash_copies;
U8 *MemoryHashFailCopy(U8 *str,CTask *task)
{
  if(++memory_hash_copies==2) throw('OutMem',TRUE);
  return MemoryStrNew(str,task);
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
}
