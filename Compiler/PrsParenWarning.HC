U0 ParenWarning(CCmpCtrl *cc)
{
  if (Bt(&cc->opts,OPTf_WARN_PAREN) &&
	!(cc->lex_include_stk->flags&LFSF_DEFINE))
    LexWarn(cc,"Unnecessary parenthesis ");
}

