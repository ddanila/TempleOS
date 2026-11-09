#ifndef I386_LEX_INPUT_INCLUDED
#define I386_LEX_INPUT_INCLUDED
#include "/Compiler/LexInput.HH"
#include "/Compiler/I386/LexFiles.HH"
class CI386LexCharSource {
  CI386Heap *heap;
  I64 *compiled_lines;
};
public extern U0 I386LexDocFormatProvider(U8 *format);
public extern I64 I386LexSourceRead(U8 *context,CCmpCtrl *cc);
//Raw file-stack reader: byte/token value, zero EOF, -1 unsupported mode or failed pop.
//Quoted document entries use the retained formatter; prompt/echo modes are separate.
public extern I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
#endif
