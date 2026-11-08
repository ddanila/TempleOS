#ifndef I386_JIT_SUPPORT_INCLUDED
#define I386_JIT_SUPPORT_INCLUDED
#include "/Kernel/CompilerTypes.HH"
class CI386JitSupport {
  CHashTable *symbols;
  U8 *code,*aot_code;
};
#endif
