#ifndef I386_COMMAND_INPUT_INCLUDED
#define I386_COMMAND_INPUT_INCLUDED
#include "/Compiler/I386/Frontend.HH"
//Opt-in header transaction. Ordinary input keeps immediate macro publication.
#define I386_INPUT_ATOMIC_DEFINES 0x100000000
//Borrowed for one synchronous input. Callbacks may inspect values only while called.
class CI386CommandInput {
  CI386Heap *heap;
  CHashClass **types;
  CI386FileServices *files;
  CI386LexIncludeService *includes;
  U8 *source,*filename,*context;
  U0 (*answer)(U8 *context,I64 value,CHashClass *value_class);
  U0 (*diagnostic)(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message);
  I64 flags;
  I64 commands,answers,errors,warnings,exception;
  //Borrowed for this synchronous input. The caller keeps it locked and live.
  CDoc *document;
  //Inspect the caught runtime exception while its compiler control is still live.
  U0 (*inspect_exception)(U8 *context,CI386Task *task,CCmpCtrl *cc,I64 exception);
  //ExePutS borrows its parent's options and optional hash context synchronously.
  //The input neither owns nor releases the context or its referenced tables.
  Bool inherit_context;
  CLexHashTableContext *hash_context;
  //Optional retained clock service, in seconds, for original task answer timing.
  F64 (*execution_time)(U8 *context);
};
extern Bool I386CommandInput(CI386CommandInput *input);
#endif
