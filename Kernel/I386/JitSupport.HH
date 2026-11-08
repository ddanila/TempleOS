#ifndef I386_JIT_SUPPORT_INCLUDED
#define I386_JIT_SUPPORT_INCLUDED
#include "/Kernel/CompilerTypes.HH"
class CI386JitSupport {
  CHashTable *symbols;
  U8 *code,*aot_code;
  U8 *resolve,*locals,*globals,*unresolved_add,*optimize,*compile,*poll,*lex,*ext_str;
  I64 lex_stage;
  U8 *expression,*expression_i64,*expression_f64,*expression_bin,*is_expression_bin,*stream;
  I64 prs_stage;
};
#endif
