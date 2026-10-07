#ifndef MENU_PARSE_SERVICES_INCLUDED
#define MENU_PARSE_SERVICES_INCLUDED
class CMenuParseServices {
  U8 *context;
  I64 (*lex)(U8 *context,CCmpCtrl *cc);
  I64 (*integer_expression)(U8 *context,CCmpCtrl *cc);
  U0 (*except)(U8 *context,CCmpCtrl *cc,U8 *message);
};
#endif
