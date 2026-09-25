#ifndef I386_FRONTEND_INCLUDED
#define I386_FRONTEND_INCLUDED
#include "/Compiler/I386/NativeSymbol.HH"
#include "/Compiler/I386/Lex.HH"
extern class CI386FileServices;
extern Bool I386FrontendStatement(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols,I64 flags);
extern U8 *I386FrontendCommand(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols,I64 *raw_type);
extern Bool I386FrontendPublish(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *symbols);
//Inspect a generated function while its private compilation control is live.
extern Bool I386FrontendCodeSpan(CPrsSymbolServices *symbols,U8 *address,I64 *bytes,I64 **data_start);
class CI386FrontendRelocView {
  I64 offset;
  U8 *name;
};
//Inspect named call relocations. Borrowed names remain valid while the
//function and its compilation control live.
extern I64 I386FrontendCodeRelocs(CPrsSymbolServices *symbols,U8 *address,
  CI386FrontendRelocView *views,I64 capacity);
//Package selected live HolyC functions, named calls and function addresses,
//and their literal pools as one relocatable T32M. NULL output queries size.
extern I64 I386FrontendModulePack(CPrsSymbolServices *symbols,CHashFun **functions,
  I64 count,U8 *output,I64 capacity);
//Add selected scalar globals as named mutable data exports in the same image.
extern I64 I386FrontendModulePackData(CPrsSymbolServices *symbols,CHashFun **functions,
  I64 count,CHashGlblVar **globals,I64 global_count,U8 *output,I64 capacity);
extern CPrsSymbolServices *I386FrontendServices(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386LexIncludeService *includes);
extern Bool I386ScalarTypesCheck(CHashClass **roots,Bool record);
extern Bool I386LoadScalarTypes(CI386Heap *heap,CHashClass **types,
  CI386FileServices *files,CI386LexIncludeService *includes,CHashClass **roots=0);
//Parse the original scalar-type bootstrap source with shared grammar and publish
//its six class graphs. Errors throw; caller must unwind its active control.
extern Bool I386BootstrapScalars(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,
  CI386LexIncludeService *includes);
#endif
