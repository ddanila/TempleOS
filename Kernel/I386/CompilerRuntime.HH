#ifndef I386_COMPILER_RUNTIME_INCLUDED
#define I386_COMPILER_RUNTIME_INCLUDED
#include "/Compiler/I386/LexInput.HH"
#include "/Compiler/I386/LexInclude.HH"
#include "/Compiler/I386/Control.HH"
#include "/Kernel/I386/TaskSymbols.HH"
#define I386_COMPILER_SERVICES_VERSION 18
//ABI 18: caller-owned interface, borrowing code from the retained module image.
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
};
#endif
