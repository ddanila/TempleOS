#ifndef I386_PUBLIC_EXPRESSION_INCLUDED
#define I386_PUBLIC_EXPRESSION_INCLUDED
#include "/Kernel/I386/PublicLexer.HH"
public _extern _LEX_EXPRESSION I64 LexExpression(CCmpCtrl *cc);
public _extern _LEX_EXPRESSION_I64 I64 LexExpressionI64(CCmpCtrl *cc);
public _extern _LEX_EXPRESSION_F64 F64 LexExpressionF64(CCmpCtrl *cc);
public _extern _LEX_EXPRESSION_BIN U8 * LexExpression2Bin(CCmpCtrl *cc,I64 *_type=NULL);
public _extern _IS_LEX_EXPRESSION_BIN Bool IsLexExpression2Bin(CCmpCtrl *cc,U8 **_machine_code);
public _extern _PRS_STREAM_BLK U0 PrsStreamBlk(CCmpCtrl *cc);
#endif
