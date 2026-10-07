#ifndef DOC_DOLLAR_SERVICES_INCLUDED
#define DOC_DOLLAR_SERVICES_INCLUDED
//Compiler operations borrowed for one dollar-command parse. Values returned by
//expression preserve raw bits; integer_expression applies numeric conversion.
class CDocDollarServices {
  U8 *context;
  I64 (*lex)(U8 *context,CCmpCtrl *cc);
  I64 (*expression)(U8 *context,CCmpCtrl *cc);
  I64 (*integer_expression)(U8 *context,CCmpCtrl *cc);
  U8 *(*string)(U8 *context,CCmpCtrl *cc);
};
#endif
