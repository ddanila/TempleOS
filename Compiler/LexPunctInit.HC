#include "/Compiler/LexPunct.HH"
U0 LexPunctInit(U32 *first,U32 *second,U32 *third)
{
  U32 *d;
  d=first;
  d['!']=TK_NOT_EQU<<16+'=';
  d['&']=TK_AND_AND<<16+'&';
  d['*']=TK_MUL_EQU<<16+'=';
  d['+']=TK_PLUS_PLUS<<16+'+';
  d['-']=TK_DEREFERENCE<<16+'>';
  d['/']='*';
  d[':']=TK_DBL_COLON<<16+':';
  d['<']=TK_LESS_EQU<<16+'=';
  d['=']=TK_EQU_EQU<<16+'=';
  d['>']=TK_GREATER_EQU<<16+'=';
  d['^']=TK_XOR_EQU<<16+'=';
  d['|']=TK_OR_OR<<16+'|';
  d['%']=TK_MOD_EQU<<16+'=';

  d=second;
  d['&']=TK_AND_EQU<<16+'=';
  d['+']=TK_ADD_EQU<<16+'=';
  d['-']=TK_MINUS_MINUS<<16+'-';
  d['/']='/';
  d['<']=TK_SHL<<16+'<';
  d['>']=TK_SHR<<16+'>';
  d['^']=TK_XOR_XOR<<16+'^';
  d['|']=TK_OR_EQU<<16+'=';

  d=third;
  d['-']=TK_SUB_EQU<<16+'=';
  d['/']=TK_DIV_EQU<<16+'=';

}
