#include "/Compiler/LexDiagnosticsCore.HC"

U0 UndefinedExtern()
{
  PrintErr("Undefined Extern\nat %P\n",Caller);
  throw('UndefExt');
}

U0 UnusedExternWarning(CCmpCtrl *cc,CHashClass *tmpc)
{
  PrintWarn("Unused extern '%s'\n",tmpc->str);
  cc->warning_cnt++;
}

U0 ParenWarning(CCmpCtrl *cc)
{
  if (Bt(&cc->opts,OPTf_WARN_PAREN) &&
	!(cc->lex_include_stk->flags&LFSF_DEFINE))
    LexWarn(cc,"Unnecessary parenthesis ");
}

#include "/Compiler/ICDiagnosticsCore.HC"
