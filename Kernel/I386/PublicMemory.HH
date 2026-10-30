#ifndef I386_PUBLIC_MEMORY_INCLUDED
#define I386_PUBLIC_MEMORY_INCLUDED
#include "/Kernel/I386/PublicTaskTypes.HH"
#include "/Kernel/MemoryAllocTypes.HH"
#include "/Kernel/MemoryTypes.HH"
#include "/Kernel/FifoTypes.HH"
#help_index "Memory/Heap"
public _extern _AMALLOC U8 *AMAlloc(I64 size);
public _extern _ACALLOC U8 *ACAlloc(I64 size);
public _extern _AMALLOC_IDENT U8 *AMAllocIdent(U8 *src);
public _extern _ASTR_NEW U8 *AStrNew(U8 *buf);
public _extern _MALLOC U8 *MAlloc(I64 size,CTask *mem_task=0);
public _extern _FREE U0 Free(U8 *addr);
public _extern _MSIZE I64 MSize(U8 *src);
public _extern _MSIZE2 I64 MSize2(U8 *src);
public _extern _MHEAP_CTRL CHeapCtrl *MHeapCtrl(U8 *src);
public _extern _CALLOC U8 *CAlloc(I64 size,CTask *mem_task=0);
public _extern _MALLOC_ALIGNED U8 *MAllocAligned(I64 size,I64 alignment,CTask *mem_task=0,I64 misalignment=0);
public _extern _CALLOC_ALIGNED U8 *CAllocAligned(I64 size,I64 alignment,CTask *mem_task=0,I64 misalignment=0);
public _extern _MEMCPY U8 *MemCpy(U8 *dst,U8 *src,I64 cnt);
public _extern _MEMCMP I64 MemCmp(U8 *ptr1,U8 *ptr2,I64 cnt);
public _extern _MEMSET U8 *MemSet(U8 *dst,I64 val,I64 cnt);
public _extern _MALLOC_IDENT U8 *MAllocIdent(U8 *src,CTask *mem_task=0);
public _extern _STR_NEW U8 *StrNew(U8 *src,CTask *mem_task=0);
public _extern _MEM_MEASURE_START Bool MemMeasureStart(CTask *task=0);
public _extern _MEM_MEASURE_STOP Bool MemMeasureStop(I64 *base,I64 *peak,I64 *reserved_peak);
#help_index "Char/Operations"
public _extern _STRCPY U0 StrCpy(U8 *dst,U8 *src);

#help_index "Data Types/Fifo"
public _extern _FIFO_U8_NEW CFifoU8 *FifoU8New(I64 size,CTask *mem_task=0);
public _extern _FIFO_U8_DEL U0 FifoU8Del(CFifoU8 *f);
public _extern _FIFO_U8_INS Bool FifoU8Ins(CFifoU8 *f,U8 b);
public _extern _FIFO_U8_REM Bool FifoU8Rem(CFifoU8 *f,U8 *_b);
public _extern _FIFO_U8_PEEK Bool FifoU8Peek(CFifoU8 *f,U8 *_b);
public _extern _FIFO_U8_FLUSH U0 FifoU8Flush(CFifoU8 *f);
public _extern _FIFO_U8_CNT I64 FifoU8Cnt(CFifoU8 *f);
public _extern _FIFO_I64_NEW CFifoI64 *FifoI64New(I64 size,CTask *mem_task=0);
public _extern _FIFO_I64_DEL U0 FifoI64Del(CFifoI64 *f);
public _extern _FIFO_I64_INS Bool FifoI64Ins(CFifoI64 *f,I64 q);
public _extern _FIFO_I64_REM Bool FifoI64Rem(CFifoI64 *f,I64 *_q);
public _extern _FIFO_I64_PEEK Bool FifoI64Peek(CFifoI64 *f,I64 *_q);
public _extern _FIFO_I64_FLUSH U0 FifoI64Flush(CFifoI64 *f);
public _extern _FIFO_I64_CNT I64 FifoI64Cnt(CFifoI64 *f);
#endif
