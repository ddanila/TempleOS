#ifndef I386_LEX_NUMBER_INCLUDED
#define I386_LEX_NUMBER_INCLUDED
#include "/Compiler/LexNumber.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/I386/String.HH"
#include "/Kernel/I386/SoftF64.HH"
#include "/Kernel/I386/FloatMath.HH"
#include "/Kernel/CharBitmaps.HH"
public extern I64 I386LexNumber(CI386Heap *heap,CCmpCtrl *cc,I64 ch,I64 *compiled_lines);
#endif
