#ifndef COMPILER_LEX_STRING_INCLUDED
#define COMPILER_LEX_STRING_INCLUDED
#include "/Compiler/LexInput.HH"
//Reader returns a character/token, zero EOF or a negative service failure.
//The reader owns replay and input transitions. Chunk decoding owns escapes.
public extern I64 LexStringChunk(CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,CLexCharSource *source);
#endif
