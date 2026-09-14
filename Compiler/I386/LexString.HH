#ifndef I386_LEX_STRING_INCLUDED
#define I386_LEX_STRING_INCLUDED
#include "/Compiler/LexString.HH"
#include "/Kernel/StringLimits.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/I386/String.HH"
#include "/Kernel/CharBitmaps.HH"
public extern I64 I386LexStringChunk(CI386Heap *heap,CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *compiled_lines);
//Opening quote consumed. Publishes an exact-sized, heap-owned string token.
public extern I64 I386LexStringToken(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
#endif
