#ifndef I386_LEX_INPUT_INCLUDED
#define I386_LEX_INPUT_INCLUDED
#include "/Compiler/LexInput.HH"
#include "/Compiler/I386/LexFiles.HH"
//Raw file-stack reader: byte/token value, zero EOF, -1 unsupported mode or failed pop.
//Document, interactive prompt and echo services remain separate integration work.
public extern I64 I386LexRawChar(CI386Heap *heap,CCmpCtrl *cc,I64 *compiled_lines);
#endif
