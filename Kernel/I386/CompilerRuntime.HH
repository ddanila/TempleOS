#ifndef I386_COMPILER_RUNTIME_INCLUDED
#define I386_COMPILER_RUNTIME_INCLUDED
#include "/Compiler/I386/LexInput.HH"
#include "/Compiler/I386/LexInclude.HH"
#include "/Compiler/I386/Control.HH"
#include "/Compiler/I386/OptBranch.HH"
#include "/Compiler/I386/OptPass012.HH"
#include "/Compiler/I386/NativeEmit.HH"
#include "/Compiler/I386/NativeBackend.HH"
#include "/Kernel/I386/TaskSymbols.HH"
#include "/Compiler/I386/NativeExpression.HH"
#include "/Compiler/I386/NativeType.HH"
#include "/Compiler/I386/ParserMemory.HH"
#include "/Compiler/I386/ParserToken.HH"
#include "/Compiler/I386/NativeDeclaration.HH"
#include "/Compiler/I386/NativeSymbol.HH"
#include "/Compiler/I386/PublishClasses.HH"
#include "/Compiler/I386/Frontend.HH"
#define I386_COMPILER_SERVICES_VERSION 30
//ABI 30: caller-owned interface, borrowing code from the retained module image.
//Detach all users before unloading; the boot kernel retains it for its lifetime.
class CI386CompilerServices {
  U32 version,bytes;
  I64 (*string_chunk)(CI386Heap *heap,CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *compiled_lines);
  I64 (*number_token)(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines);
  I64 (*char_token)(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
  I64 (*punct_token)(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines);
  I64 (*ident_scan)(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *buf,I64 capacity,CHash **entry,I64 *compiled_lines);
  I64 (*ident_token)(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *macro_filename,I64 *compiled_lines);
  I64 (*string_token)(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
  I64 (*next_token)(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,I64 *compiled_lines);
  I64 (*next_token_with_includes)(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,I64 *compiled_lines,CI386LexIncludeService *includes);
  CCmpCtrl *(*control_new)(CI386Heap *heap,U8 *buffer,I64 flags,U8 *name,CHashTable *symbols,U32 *alpha_numeric,CI386Task *task);
  Bool (*control_del)(CI386Heap *heap,CCmpCtrl *cc,U0 (*document)(U8 *context,CDoc *document),U8 *context);
  Bool (*symbols_init)(CI386Task *task,CI386Heap *heap,CHashTable *table,I64 buckets);
  Bool (*control_enter)(CI386Heap *heap,CCmpCtrl *cc,U0 (*document)(U8 *context,CDoc *document),U8 *context);
  Bool (*control_leave)(CI386Heap *heap,CCmpCtrl *cc);
  Bool (*control_drain)(CI386Task *task);
  Bool (*control_unwind)(CI386Task *task,CCmpCtrl *boundary);
  CIntermediateCode *(*code_add)(CI386Heap *heap,CCmpCtrl *cc,I64 opcode,I64 arg,CHashClass *type,I64 flags);
  CCodeMisc *(*code_misc)(CI386Heap *heap,CCmpCtrl *cc,I64 type);
  Bool (*code_discard)(CI386Heap *heap,CCmpCtrl *cc,U0 (*label)(U8 *context,CCmpCtrl *cc,U8 *name,Bool undefined),U8 *context);
  CCodeCtrl *(*code_save)(CI386Heap *heap,CCmpCtrl *cc);
  Bool (*code_push)(CI386Heap *heap,CCmpCtrl *cc);
  CCodeCtrl *(*code_pop)(CI386Heap *heap,CCmpCtrl *cc);
  Bool (*code_free)(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header);
  Bool (*code_append)(CI386Heap *heap,CCmpCtrl *cc,CCodeCtrl *header);
  Bool (*code_retire)(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node);
  CIntermediateCode *(*code_branch)(CI386Heap *heap,CCmpCtrl *cc,CIntermediateCode *node);
  CIntermediateCode *(*code_optimize)(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,
    U0 (*diagnostic)(CCmpCtrl *cc,CIntermediateCode *node,I64 reason));
  CI386Out *(*out_new)(CI386Heap *heap,CCmpCtrl *cc);
  Bool (*out_del)(CI386Heap *heap,CCmpCtrl *cc,CI386Out *out);
  Bool (*backend)(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386Out *out,CI386BackendStatus *status);
  Bool (*expression)(CI386Heap *heap,CCmpCtrl *cc,CPrsExpressionServices *services,I64 *precedence,Bool end_exp,CPrsStk *stack);
  CHashClass *(*parse_type)(CI386Heap *heap,CCmpCtrl *cc,CPrsTypeServices *services,
    CHashClass **first,I64 *mode,CMemberLst *member,U8 **ident,CHashFun **fun,
    CHashExport **export_entry,CArrayDim *dim,I64 flags);
  U8 *(*parser_alloc)(CI386Heap *heap,CCmpCtrl *cc,I64 bytes,Bool zeroed);
  Bool (*parser_free)(CI386Heap *heap,CCmpCtrl *cc,U8 *allocation);
  I64 (*parser_token)(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,
    I64 *compiled_lines,CI386LexIncludeService *includes);
  Bool (*parse_declarations)(CI386Heap *heap,CCmpCtrl *cc,CPrsDeclarationServices *services,
    CHashClass *type,I64 mode,I64 union_base);
  Bool (*code_init)(CI386Heap *heap,CCmpCtrl *cc);
  CHashClass *(*parse_class)(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *services,
    I64 keyword,I64 flags,Bool is_extern);
  CHashFun *(*parse_fun_join)(CI386Heap *heap,CCmpCtrl *cc,CPrsSymbolServices *services,
    CHashClass *return_type,U8 *name,I64 flags);
  Bool (*publish_classes)(CI386Heap *heap,CCmpCtrl *cc,CHashTable *source);
  Bool (*bootstrap_scalars)(CI386Heap *heap,CCmpCtrl *cc,CHashClass **types,CI386LexIncludeService *includes);
  Bool (*load_scalar_types)(CI386Heap *heap,CHashClass **types,CI386FileServices *files,CI386LexIncludeService *includes,CHashClass **roots=0);
  Bool (*scalar_types_check)(CHashClass **roots,Bool record);
};
#endif
