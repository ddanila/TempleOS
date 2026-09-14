#ifndef I386_FRONTEND_INCLUDED
#define I386_FRONTEND_INCLUDED
#include "/Compiler/I386/NativeSymbol.HH"
#include "/Compiler/I386/Lex.HH"
extern class CI386FileServices;
extern Bool I386FrontendStatement(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols,I64 flags);
extern CPrsSymbolServices *I386FrontendServices(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386LexIncludeService *includes);
extern Bool I386ScalarTypesCheck(CHashClass **roots,Bool record);
extern Bool I386LoadScalarTypes(CI386Heap *heap,CHashClass **types,
  CI386FileServices *files,CI386LexIncludeService *includes,CHashClass **roots=0);
//Parse the original scalar-type bootstrap source with shared grammar and publish
//its six class graphs. Errors throw; caller must unwind its active control.
extern Bool I386BootstrapScalars(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,
  CI386LexIncludeService *includes);
#endif
