#ifndef I386_LEX_INCLUDED
#define I386_LEX_INCLUDED
#include "/Compiler/I386/LexIdent.HH"
#include "/Compiler/I386/LexString.HH"
#include "/Compiler/I386/LexNumber.HH"
#include "/Compiler/I386/LexChar.HH"
#include "/Compiler/I386/LexPunct.HH"
//Token/EOF, -1 service error, -3 identifier limit, -4 unavailable directive, -5 character limit.
public extern I64 I386LexNext(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,U8 *macro_filename,I64 *compiled_lines);
#endif
