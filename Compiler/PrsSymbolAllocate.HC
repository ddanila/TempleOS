#include "/Compiler/SymbolInit.HC"
CHashClass *PrsClassNew()
{
  CHashClass *res=CAlloc(sizeof(CHashClass)*(PTR_STARS_NUM+1),Fs->code_heap);
  PrsClassInit(res);
  return res;
}

CHashFun *PrsFunNew()
{
  CHashFun *res=CAlloc(sizeof(CHashFun)*(PTR_STARS_NUM+1),Fs->code_heap);
  PrsFunInit(res);
  return res;
}

