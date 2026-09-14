#ifndef I386_LEX_DEFINE_INCLUDED
#define I386_LEX_DEFINE_INCLUDED
#include "/Compiler/LexDefine.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/I386/Cpu.HH"
//Returns heap-owned NUL-terminated replacement text, or zero on failure.
//Does not publish a definition/name or rewind consumed input.
public extern U8 *I386LexDefineBody(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
#endif
