#ifndef I386_LEX_INCLUDED
#define I386_LEX_INCLUDED
#include "/Compiler/Keywords.HH"
#include "/Compiler/I386/LexInclude.HH"
#include "/Compiler/I386/LexDefine.HH"
#include "/Compiler/I386/LexIdent.HH"
#include "/Compiler/I386/LexString.HH"
#include "/Compiler/I386/LexNumber.HH"
#include "/Compiler/I386/LexChar.HH"
#include "/Compiler/I386/LexPunct.HH"
//Token/EOF, -1 service error, -3 identifier limit, -4 unavailable directive, -5 character limit.
public extern I64 I386LexNext(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,U8 *macro_filename,I64 *compiled_lines);
//Explicit include service; recursive directives and conditional scans retain this binding.
public extern I64 I386LexNextWithIncludes(CI386Heap *heap,CCmpCtrl *cc,CLexPunctTables *tables,
  U8 *macro_filename,I64 *compiled_lines,CI386LexIncludeService *includes);
#endif
