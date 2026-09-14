#ifndef I386_PARSER_MEMORY_INCLUDED
#define I386_PARSER_MEMORY_INCLUDED
#include "/Compiler/I386/Control.HH"
//Temporary parser storage; exact requested size, independently tracked until
//explicit release or control deletion. Do not publish beyond the control lifetime.
extern U8 *I386ParserAlloc(CI386Heap *heap,CCmpCtrl *cc,I64 bytes,Bool zeroed=TRUE);
extern Bool I386ParserFree(CI386Heap *heap,CCmpCtrl *cc,U8 *allocation);
#endif
