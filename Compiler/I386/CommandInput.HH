#ifndef I386_COMMAND_INPUT_INCLUDED
#define I386_COMMAND_INPUT_INCLUDED
#include "/Compiler/I386/Frontend.HH"
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
};
extern Bool I386CommandInput(CI386CommandInput *input);
#endif
