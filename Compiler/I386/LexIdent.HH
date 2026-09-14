#ifndef I386_LEX_IDENT_INCLUDED
#define I386_LEX_IDENT_INCLUDED
#include "/Compiler/LexIdent.HH"
#include "/Compiler/I386/LexInput.HH"
#include "/Kernel/I386/Bits.HH"
#include "/Kernel/I386/Hash.HH"
//Caller owns output storage. No token/string publication, macro expansion or final lookahead.
//On success, entry is a borrowed global symbol or zero; cc.local_var_entry is resolved.
public extern I64 I386LexIdentScan(CI386Heap *heap,CCmpCtrl *cc,I64 ch,U8 *buf,I64 capacity,CHash **entry,I64 *compiled_lines);
#endif
