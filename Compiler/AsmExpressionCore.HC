I64 AsmLexExpression(CCmpCtrl *cc)
{
  U8 *machine_code;
  I64 res=0;
  cc->asm_undef_hash=NULL;
  cc->flags&=~(CCF_UNRESOLVED+CCF_LOCAL);
  cc->abs_cnts=0;
  if (!IsLexExpression2Bin(cc,&machine_code))
    LexSkipEol(cc);
  else {
    if (cc->abs_cnts.externs)
      LexExcept(cc,"Extern Not Allowed at ");
    if (cc->flags & CCF_UNRESOLVED)
      LexExcept(cc,"Undefined sym at ");
    res=Call(machine_code);
    Free(machine_code);
  }
  return res;
}

U0 AsmLineLst(CCmpCtrl *cc)
{
  CAOTCtrl *aotc=cc->aotc;
  CLexFile *tmpf=cc->lex_include_stk;
  CDocEntry *doc_e=tmpf->line_start,*doc_e2;
  if (aotc->lst && aotc->lst_last_lfn==tmpf && doc_e) {
    if (doc_e2=aotc->lst_last_line) {
      if (tmpf->flags& LFSF_DOC) {
	while (doc_e2->y<doc_e->y) {
	  "%h*c%08X ",24-aotc->lst_col,CH_SPACE,aotc->lst_last_rip;
	  aotc->lst_col=0;
	  doc_e2=LexPutLine(cc,doc_e2);
	}
      } else {
	while (*doc_e2(U8 *) && doc_e2!=doc_e) {
	  "%h*c%08X ",24-aotc->lst_col,CH_SPACE,aotc->lst_last_rip;
	  aotc->lst_col=0;
	  doc_e2=LexPutLine(cc,doc_e2);
	}
      }
      aotc->lst_last_line=doc_e2;
    } else
      aotc->lst_last_line=doc_e;
  } else {
    aotc->lst_last_line=NULL;
    aotc->lst_last_lfn=tmpf;
  }
  aotc->lst_last_rip=aotc->rip;
}
