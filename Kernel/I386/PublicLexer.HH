#ifndef I386_PUBLIC_LEXER_INCLUDED
#define I386_PUBLIC_LEXER_INCLUDED
#include "/Kernel/I386/PublicDocument.HH"
public _extern _LEX I64 Lex(CCmpCtrl *cc);
public _extern _LEX_EXT_STR U8 *LexExtStr(CCmpCtrl *cc,I64 *_size=NULL,Bool lex_next=TRUE);
#endif
