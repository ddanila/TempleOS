#include "/Kernel/MenuTypes.HH"
//Original menu grammar using one retained compiler context per call.
#include "/Kernel/MessageCodes.HH"
#include "/Adam/MenuParseServices.HH"
extern CMenu *NativeMenuNew(U8 *source,I64 flags=0,CTask *task=NULL);
U0 NativeMenuExcept(U8 *context,CCmpCtrl *cc,U8 *message)
{
  CI386DocParser *parser=context;
  CPrsExpressionServices *expression=parser->symbols->declarations->expression;
  if(parser->control!=cc) throw('Compiler',TRUE);
  (*expression->report)(expression->context,cc,0,message);
}
#define I386_MENU_PARSE_BINDINGS 1
#define MenuNew NativeMenuNew
#include "/Adam/MenuParseCore.HC"
CMenu *NativeMenuNew(U8 *source,I64 flags=0,CTask *task=NULL)
{
  CI386DocParser parser;
  CMenuParseServices services;
  CMenu *menu=NULL;
  NativeDocParserOpen(&parser,source);
  services.context=&parser;
  services.lex=&NativeDocDollarLex;
  services.integer_expression=&NativeDocDollarInteger;
  services.except=&NativeMenuExcept;
  try { menu=MenuBuildCore(&services,parser.control,flags,task); }
  catch { NativeDocParserClose(&parser); }
  NativeDocParserClose(&parser);
  return menu;
}
