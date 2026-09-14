#ifndef COMPILER_KEYWORD_TABLE_INCLUDED
#define COMPILER_KEYWORD_TABLE_INCLUDED
#include "/Compiler/Keywords.HH"
#include "/Kernel/SymbolTypes.HH"
#define COMPILER_KEYWORDS_NUM 73
class CCompilerKeyword { U8 name[12]; U32 type; I64 value; };
public extern CCompilerKeyword compiler_keywords[COMPILER_KEYWORDS_NUM];
#endif
