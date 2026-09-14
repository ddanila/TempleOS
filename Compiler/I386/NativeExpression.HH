#ifndef I386_NATIVE_EXPRESSION_INCLUDED
#define I386_NATIVE_EXPRESSION_INCLUDED
#include "/Compiler/PrsExpression.HH"
#include "/Compiler/I386/Control.HH"
//Borrow a complete parser environment. Failed parses require control unwind.
extern Bool I386ParseExpression(CI386Heap *heap,CCmpCtrl *cc,CPrsExpressionServices *services,
  I64 *precedence,Bool end_exp,CPrsStk *stack=0);
#endif
