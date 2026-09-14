#ifndef I386_LEX_STRING_INCLUDED
#define I386_LEX_STRING_INCLUDED
#include "/Compiler/LexString.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/I386/String.HH"
#include "/Kernel/CharBitmaps.HH"
public extern I64 I386LexStringChunk(CI386Heap *heap,CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,I64 *compiled_lines);
#endif
