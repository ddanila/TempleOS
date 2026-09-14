//Shared function-body construction, compilation and symbol finalization.
#include "/Compiler/PrsFunction.HH"
U0 PrsFunCore(CPrsFunctionServices *services,CCmpCtrl *cc,CHashClass *tmp_return,U8 *name,I64 fsp_flags)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsSymbolServices *symbols=globals->symbols;
  CPrsDeclarationServices *declarations=symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsInitializerServices *initializers=globals->initializers;
  CMemberLst *tmpm;
  CCodeMisc *saved_leave_label;
  I64 i,j,size,*r;
  Bool old_trace;

  cc->fun_lex_file=cc->lex_include_stk;
  cc->min_line=cc->max_line=cc->lex_include_stk->line_num;

  cc->flags&=~CCF_NO_REG_OPT;
  cc->htc.local_var_lst=cc->htc.fun=PrsFunJoinCore(symbols,cc,tmp_return,name,fsp_flags);

  (*expression->push)(expression->context,cc);
  Btr(&cc->flags,CCf_PASS_TRACE_PRESENT);
  (*expression->init)(expression->context,cc);
  PrsEmit(expression,cc,IC_ENTER,0,0);
  saved_leave_label=cc->lb_leave;
  cc->lb_leave=(*expression->misc)(expression->context,cc,CMT_LABEL);
  cc->flags&=~CCF_HAS_RETURN;
  (*services->statement)(services->context,cc,0,NULL,0);

  if (cc->max_line<cc->min_line)
    cc->max_line=cc->min_line;

  if (cc->htc.fun->return_class->size && !(cc->flags&CCF_HAS_RETURN))
    (*expression->report)(expression->context,cc,1,"Function should return val ");
  PrsEmit(expression,cc,IC_LABEL,cc->lb_leave,0);
  cc->lb_leave=saved_leave_label;
  PrsEmit(expression,cc,IC_LEAVE,0,cc->htc.fun->return_class);
  cc->htc.fun->size&=~7;
  if (cc->flags&CCF_AOT_COMPILE) {
    if (cc->flags&CCF_TARGET_I386)
      while (cc->aotc->rip&7) (*initializers->store_u8)(initializers->context,cc,0);
    cc->htc.fun->exe_addr=cc->aotc->rip;
    cc->htc.fun->type|=HTF_EXPORT|HTF_RESOLVE;
    r=(*services->compile)(services->context,cc,&size,&cc->htc.fun->dbg_info,NULL);
    if (r) {
      j=(size+7)>>3;
      for (i=0;i<j;i++)
	(*declarations->store_u64)(declarations->context,cc,r[i]);
      (*declarations->release)(declarations->context,r);
    }
  } else {
    old_trace=Btr(&cc->opts,OPTf_TRACE);
    cc->htc.fun->exe_addr=(*services->compile)(services->context,
	  cc,&size,&cc->htc.fun->dbg_info,NULL);
    if (old_trace) {
      Bts(&cc->opts,OPTf_TRACE);
      (*services->disassemble)(services->context,cc->htc.fun->exe_addr,size);
    }
    (*globals->resolve)(globals->context,cc,cc->htc.fun->str);
  }
  LBtr(&cc->htc.fun->flags,Cf_EXTERN);
  (*expression->pop)(expression->context,cc);
  tmpm=cc->htc.fun->member_lst_and_root;
  while (tmpm) {
    if (tmpm->flags & MLF_NO_UNUSED_WARN) {
      if (tmpm->use_cnt>1&&StrCmp(tmpm->str,"_anon_"))
	(*services->member_warning)(services->context,cc,tmpm,TRUE);
    } else if (!tmpm->use_cnt && (*symbols->option)(symbols->context,OPTf_WARN_UNUSED_VAR))
      (*services->member_warning)(services->context,cc,tmpm,FALSE);
    tmpm=tmpm->next;
  }
  cc->htc.local_var_lst=cc->htc.fun=cc->fun_lex_file=NULL;
}
