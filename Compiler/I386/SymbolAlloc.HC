#include "/Compiler/I386/SymbolAlloc.HH"
#include "/Compiler/SymbolInit.HC"
#include "/Kernel/I386/Cpu.HH"
//Explicit-heap try-allocation. Public Fs/code-heap selection and OutMem are separate.
public CHashClass *I386PrsClassNew(CI386Heap *heap)
{
  U32 flags=I386IrqSave;
  CHashClass *res=I386HeapAlloc(heap,sizeof(CHashClass)*(PTR_STARS_NUM+1),TRUE);
  if(res) PrsClassInit(res);
  I386IrqRestore(flags); return res;
}
public CHashFun *I386PrsFunNew(CI386Heap *heap)
{
  U32 flags=I386IrqSave;
  CHashFun *res=I386HeapAlloc(heap,sizeof(CHashFun)*(PTR_STARS_NUM+1),TRUE);
  if(res) PrsFunInit(res);
  I386IrqRestore(flags); return res;
}
public CMemberLst *I386MemberLstNew(CI386Heap *heap,I64 reg_num)
{
  U32 flags=I386IrqSave;
  CMemberLst *res=I386HeapAlloc(heap,sizeof(CMemberLst),TRUE);
  if(res) res->reg=reg_num;
  I386IrqRestore(flags); return res;
}
