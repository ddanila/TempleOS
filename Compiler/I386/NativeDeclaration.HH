#ifndef I386_NATIVE_DECLARATION_INCLUDED
#define I386_NATIVE_DECLARATION_INCLUDED
#include "/Compiler/PrsDeclaration.HH"
#include "/Compiler/I386/Control.HH"
extern Bool I386ParseDeclarations(CI386Heap *heap,CCmpCtrl *cc,CPrsDeclarationServices *services,
  CHashClass *type,I64 mode,I64 union_base=0);
#endif
