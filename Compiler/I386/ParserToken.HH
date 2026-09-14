#ifndef I386_PARSER_TOKEN_INCLUDED
#define I386_PARSER_TOKEN_INCLUDED
#include "/Compiler/I386/Control.HH"
#include "/Compiler/I386/LexInclude.HH"
//Parser token stream: strings transferred by clearing cur_str stay control-owned.
//Use this entry consistently; raw lexer calls do not update parser ownership.
//Invalid setup returns -1. Lexer failures throw Compiler; tracking OOM throws OutMem.
extern I64 I386ParserToken(CI386Heap *heap,CCmpCtrl *cc,U8 *macro_filename,
  I64 *compiled_lines,CI386LexIncludeService *includes);
#endif
