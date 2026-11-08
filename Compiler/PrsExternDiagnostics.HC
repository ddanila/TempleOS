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

