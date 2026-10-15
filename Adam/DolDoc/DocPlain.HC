#help_index "DolDoc"

#include "/Adam/DolDoc/DocDollarServices.HH"
I64 DocDollarHostLex(U8 *context,CCmpCtrl *cc){return Lex(cc);}
I64 DocDollarHostExpression(U8 *context,CCmpCtrl *cc){return LexExpression(cc);}
I64 DocDollarHostInteger(U8 *context,CCmpCtrl *cc){return LexExpressionI64(cc);}
U8 *DocDollarHostString(U8 *context,CCmpCtrl *cc){return LexExtStr(cc);}
U0 DocDollarHostServices(CDocDollarServices *services)
{
  services->context=NULL; services->lex=&DocDollarHostLex;
  services->expression=&DocDollarHostExpression;
  services->integer_expression=&DocDollarHostInteger;
  services->string=&DocDollarHostString;
}
#include "/Adam/DolDoc/DocDollarFlagsCore.HC"
I64 PrsDocFlagSingle(CCmpCtrl *cc,I64 *_de_flags,U32 *_type,Bool turn_on)
{
  CDocDollarServices services;DocDollarHostServices(&services);
  return PrsDocFlagSingleCore(&services,cc,_de_flags,_type,turn_on);
}
I64 PrsDocFlags(CCmpCtrl *cc,I64 *_de_flags,U32 *_type)
{
  CDocDollarServices services;DocDollarHostServices(&services);
  return PrsDocFlagsCore(&services,cc,_de_flags,_type);
}

#include "/Adam/DolDoc/DocPlainTextCore.HC"

#include "/Adam/DolDoc/DocDollarParseCore.HC"
CDocEntry *PrsDollarCmd(CDoc *doc,U8 *st)
{
  CDocDollarServices services;
  CCmpCtrl *cc=CmpCtrlNew(st,CCF_DONT_FREE_BUF);
  CDocEntry *result;
  DocDollarHostServices(&services);
  try { result=PrsDollarCmdCore(&services,cc,doc,st); }
  catch { CmpCtrlDel(cc); }
  CmpCtrlDel(cc);
  return result;
}

#include "/Adam/DolDoc/DocTransformCore.HC"
