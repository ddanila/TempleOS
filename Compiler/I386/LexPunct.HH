#ifndef I386_LEX_PUNCT_INCLUDED
#define I386_LEX_PUNCT_INCLUDED
#include "/Compiler/LexPunct.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/CharBitmaps.HH"
public extern I64 I386LexPunct(CI386Heap *heap,CCmpCtrl *cc,I64 ch,CLexPunctTables *tables,I64 *compiled_lines);
#endif
