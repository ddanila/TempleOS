#ifndef I386_LEX_IDENT_INCLUDED
#define I386_LEX_IDENT_INCLUDED
#include "/Compiler/LexIdent.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/I386/Hash.HH"
//Caller owns output storage. No token/string publication, macro expansion or final lookahead.
//On success, entry is a borrowed global symbol or zero; cc.local_var_entry is resolved.
public extern I64 I386LexIdentScan(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *buf,I64 capacity,CHash **entry,I64 *compiled_lines);
//Returns TK_IDENT, -2 expanded macro, -3 overlength, or -1 failure.
//Published cur_str belongs to heap. Macro diagnostics use the caller's filename.
public extern I64 I386LexIdentToken(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *macro_filename,I64 *compiled_lines);
#endif
