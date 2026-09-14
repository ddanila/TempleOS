#ifndef I386_NATIVE_SYMBOL_INCLUDED
#define I386_NATIVE_SYMBOL_INCLUDED
#include "/Compiler/PrsSymbol.HH"
#include "/Compiler/I386/Control.HH"
extern CHashClass *I386ParseClass(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *services,
  I64 keyword,I64 flags,Bool is_extern);
extern CHashFun *I386ParseFunJoin(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *services,
  CHashClass *return_type,U8 *name,I64 flags);
#endif
