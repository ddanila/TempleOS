#ifndef I386_CONTEXT_INCLUDED
#define I386_CONTEXT_INCLUDED
class CI386Context { U32 esp; };
public extern Bool I386ContextInit(CI386Context *context,U8 *stack,I64 size,
  U0 (*entry)(I64 arg),I64 arg,U0 (*exit)());
#endif
