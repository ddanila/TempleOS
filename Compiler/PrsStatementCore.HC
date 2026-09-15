//Complete production statement parser with explicit environment services.
#include "/Compiler/PrsStatement.HH"
//Intrusive parser queues use the target pointer width.
class CPrsQueue { CPrsQueue *next,*last; };
U0 PrsQueueInit(CPrsQueue *head) { head->next=head->last=head; }
U0 PrsQueueInsert(CPrsQueue *node,CPrsQueue *after)
{ node->next=after->next; node->last=after; after->next->last=node; after->next=node; }
U0 PrsQueueRemove(CPrsQueue *node)
{ node->last->next=node->next; node->next->last=node->last; }

U0 PrsIfCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt,CCodeMisc *lb_break)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CCodeMisc *lb,*lb1;
  I64 k;
  if (cc->token!='(')
    (*expression->report)(expression->context,cc,0,"Expecting '(' at ");
  (*expression->lex)(expression->context,cc);
  if (!(*expression->expression)(expression->context,cc,NULL,FALSE,NULL))
    throw('Compiler');
  if (cc->token!=')')
    (*expression->report)(expression->context,cc,0,"Missing ')' at ");
  (*expression->lex)(expression->context,cc);
  lb=(*expression->misc)(expression->context,cc,CMT_LABEL);
  PrsEmit(expression,cc,IC_BR_ZERO,lb,0);
  PrsStmtCore(services,cc,try_cnt,lb_break);
  k=PrsKeyWord(cc);
  if (k==KW_ELSE) {
    (*expression->lex)(expression->context,cc);
    lb1=(*expression->misc)(expression->context,cc,CMT_LABEL);
    PrsEmit(expression,cc,IC_JMP,lb1,0);
    PrsEmit(expression,cc,IC_LABEL,lb,0);
    PrsStmtCore(services,cc,try_cnt,lb_break);
    PrsEmit(expression,cc,IC_LABEL,lb1,0);
  } else
    PrsEmit(expression,cc,IC_LABEL,lb,0);
}

U0 PrsWhileCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CCodeMisc *lb,*lb_done;
  if (cc->token!='(')
    (*expression->report)(expression->context,cc,0,"Expecting '(' at ");
  (*expression->lex)(expression->context,cc);
  lb=(*expression->misc)(expression->context,cc,CMT_LABEL);
  PrsEmit(expression,cc,IC_LABEL,lb,0);
  if (!(*expression->expression)(expression->context,cc,NULL,FALSE,NULL))
    throw('Compiler');
  if (cc->token!=')')
    (*expression->report)(expression->context,cc,0,"Missing ')' at ");
  (*expression->lex)(expression->context,cc);
  lb_done=(*expression->misc)(expression->context,cc,CMT_LABEL);
  PrsEmit(expression,cc,IC_BR_ZERO,lb_done,0);
  PrsStmtCore(services,cc,try_cnt,lb_done);
  PrsEmit(expression,cc,IC_JMP,lb,0);
  PrsEmit(expression,cc,IC_LABEL,lb_done,0);
}

U0 PrsDoWhileCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CCodeMisc *lb,*lb_done;
  lb=(*expression->misc)(expression->context,cc,CMT_LABEL);
  lb_done=(*expression->misc)(expression->context,cc,CMT_LABEL);
  PrsEmit(expression,cc,IC_LABEL,lb,0);
  PrsStmtCore(services,cc,try_cnt,lb_done);
  if (PrsKeyWord(cc)!=KW_WHILE)
    (*expression->report)(expression->context,cc,0,"Missing 'while' at");
  if ((*expression->lex)(expression->context,cc)!='(')
    (*expression->report)(expression->context,cc,0,"Expecting '(' at ");
  (*expression->lex)(expression->context,cc);
  if (!(*expression->expression)(expression->context,cc,NULL,FALSE,NULL))
    throw('Compiler');
  if (cc->token!=')')
    (*expression->report)(expression->context,cc,0,"Missing ')' at ");
  PrsEmit(expression,cc,IC_BR_NOT_ZERO,lb,0);
  PrsEmit(expression,cc,IC_LABEL,lb_done,0);
  if ((*expression->lex)(expression->context,cc)!=';')
    (*expression->report)(expression->context,cc,0,"Missing ';' at");
  (*expression->lex)(expression->context,cc);
}

U0 PrsForCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CCodeCtrl *tmpcbh;
  CCodeMisc *lb,*lb_done;

  if (cc->token!='(')
    (*expression->report)(expression->context,cc,0,"Expecting '(' at ");
  (*expression->lex)(expression->context,cc);
  PrsStmtCore(services,cc,try_cnt);

  lb=(*expression->misc)(expression->context,cc,CMT_LABEL);
  PrsEmit(expression,cc,IC_LABEL,lb,0);
  if (!(*expression->expression)(expression->context,cc,NULL,FALSE,NULL))
    throw('Compiler');
  lb_done=(*expression->misc)(expression->context,cc,CMT_LABEL);
  PrsEmit(expression,cc,IC_BR_ZERO,lb_done,0);
  if (cc->token!=';')
    (*expression->report)(expression->context,cc,0,"Missing ';' at");
  (*expression->lex)(expression->context,cc);

  (*expression->push)(expression->context,cc);
  (*expression->init)(expression->context,cc);
  if (cc->token!=')')
    PrsStmtCore(services,cc,try_cnt,NULL,0);
  (*expression->push)(expression->context,cc);
  tmpcbh=(*services->pop_saved)(services->context,cc);
  (*expression->pop)(expression->context,cc);
  if (cc->token!=')')
    (*expression->report)(expression->context,cc,0,"Missing ')' at ");
  (*expression->lex)(expression->context,cc);

  PrsStmtCore(services,cc,try_cnt,lb_done);
  (*expression->append)(expression->context,cc,tmpcbh);
  PrsEmit(expression,cc,IC_JMP,lb,0);
  PrsEmit(expression,cc,IC_LABEL,lb_done,0);
}

class CSubSwitch {
  CSubSwitch *next,*last;
  CCodeMisc *lb_start,*lb_break;
};

class CSwitchCase {
  CSwitchCase *next;
  CCodeMisc *label;
  I64 val;
  CSubSwitch *ss;
};

U0 PrsSwitchCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CSwitchCase *header=NULL,*tmps,*tmps1;	//Leaks on except
  CSubSwitch head,*tmpss;			//Leaks on except
  CCodeMisc *lb_dft,*lb_fwd_case,*mc_jt,*lb_entry,**jmp_table;
  CIntermediateCode *tmpi_sub,*tmpi_cmp,*tmpi_jmp,*tmpi_start;
  Bool dft_found=FALSE,nobound;
  I64 i,k_start=I64_MIN,k_end,lo=I64_MAX,hi=I64_MIN,range;

  if (cc->token=='(')
    nobound=FALSE;
  else if (cc->token=='[')
    nobound=TRUE;
  else
    (*expression->report)(expression->context,cc,0,"Expecting '(' or '[' at ");
  (*expression->lex)(expression->context,cc);
  PrsQueueInit(&head);

  head.last->lb_break=(*expression->misc)(expression->context,cc,CMT_LABEL);
  head.last->lb_break->use_cnt++;
  lb_dft=(*expression->misc)(expression->context,cc,CMT_LABEL);
  lb_dft->use_cnt++;
  mc_jt=(*expression->misc)(expression->context,cc,CMT_JMP_TABLE);
  mc_jt->begin=(*expression->misc)(expression->context,cc,CMT_LABEL);
  mc_jt->begin->use_cnt++;
  if (!(*expression->expression)(expression->context,cc,NULL,FALSE,NULL))
    throw('Compiler');
  tmpi_sub=PrsEmit(expression,cc,IC_IMM_I64,0,expression->types[RT_I64]);
  PrsEmit(expression,cc,IC_SUB,0,expression->types[RT_I64]);
  tmpi_cmp=PrsEmit(expression,cc,IC_IMM_I64,0,expression->types[RT_I64]);
  if (nobound) {
    PrsEmit(expression,cc,IC_NOBOUND_SWITCH,mc_jt,0);
    if (cc->token!=']')
      (*expression->report)(expression->context,cc,0,"Missing ']' at ");
  } else {
    PrsEmit(expression,cc,IC_SWITCH,mc_jt,0);
    if (cc->token!=')')
      (*expression->report)(expression->context,cc,0,"Missing ')' at ");
  }
  if ((*expression->lex)(expression->context,cc)!='{')
    (*expression->report)(expression->context,cc,0,"Expecting '{' at ");
  (*expression->lex)(expression->context,cc);
  PrsEmit(expression,cc,IC_LABEL,mc_jt->begin,0);
  while (TRUE) {
    while (cc->token && cc->token!='}') {
sw_cont:
      switch (PrsKeyWord(cc)) {
	case KW_END:
	  goto sw_sub_end;
	case KW_START:
	  if ((*expression->lex)(expression->context,cc)==':')
	    (*expression->lex)(expression->context,cc);
	  else
	    (*expression->report)(expression->context,cc,0,"Expecting ':' at ");
	  tmpss=(*expression->allocate)(expression->context,sizeof(CSubSwitch),FALSE,FALSE);
	  PrsQueueInsert(tmpss,head.last);
	  head.last->lb_break=(*expression->misc)(expression->context,cc,CMT_LABEL);
	  head.last->lb_break->use_cnt++;
	  lb_fwd_case=(*expression->misc)(expression->context,cc,CMT_LABEL);
	  tmpi_jmp=PrsEmit(expression,cc,IC_JMP,lb_fwd_case,0);

	  tmpss->lb_start=(*expression->misc)(expression->context,cc,CMT_LABEL);
	  tmpi_start=PrsEmit(expression,cc,IC_LABEL,tmpss->lb_start,0);
	  while (cc->token && cc->token!='}') {
	    switch (PrsKeyWord(cc)) {
	      case KW_END:
		(*expression->retire)(expression->context,cc,tmpi_jmp);
		goto sw_sub_end;
	      case KW_START:
	      case KW_CASE:
	      case KW_DFT:
		if (cc->coc.coc_head.last==tmpi_start) {
		  (*expression->retire)(expression->context,cc,tmpi_jmp);
		  tmpss->lb_start=NULL;
		} else {
		  PrsEmit(expression,cc,IC_RET,0,0);
		  PrsEmit(expression,cc,IC_LABEL,lb_fwd_case,0);
		  PrsEmit(expression,cc,IC_SUB_CALL,tmpss->lb_start,0);//In case fall-thru
		}
		goto sw_cont;
	      default:
		PrsStmtCore(services,cc,try_cnt);
	    }
	  }
	  break;
	case KW_CASE:
	  if (head.next!=&head) {
	    lb_fwd_case=(*expression->misc)(expression->context,cc,CMT_LABEL);
	    tmpi_jmp=PrsEmit(expression,cc,IC_JMP,lb_fwd_case,0);//In case fall-thru
	  }
	  (*expression->lex)(expression->context,cc);
	  lb_entry=(*expression->misc)(expression->context,cc,CMT_LABEL);
	  PrsEmit(expression,cc,IC_LABEL,lb_entry,0);
	  lb_entry->use_cnt++;
	  if (head.next!=&head) {
	    tmpss=head.next;
	    while (tmpss!=&head) {
	      if (tmpss->lb_start)
		PrsEmit(expression,cc,IC_SUB_CALL,tmpss->lb_start,0);
	      tmpss=tmpss->next;
	    }
	    PrsEmit(expression,cc,IC_LABEL,lb_fwd_case,0);
	  }
	  if (cc->token==':') {
	    if (k_start==I64_MIN)
	      k_start=0;
	    else
	      k_start++;
	  } else
	    k_start=(*types->integer_expression)(types->context,cc);
	  if (k_start<lo) lo=k_start;
	  if (k_start>hi) hi=k_start;
	  if (cc->token==':') {
	    (*expression->lex)(expression->context,cc);
	    tmps=(*expression->allocate)(expression->context,sizeof(CSwitchCase),FALSE,FALSE);
	    tmps->label=lb_entry;
	    tmps->val=k_start;
	    tmps->next=header;
	    header=tmps;
	  } else if (cc->token==TK_ELLIPSIS) {
	    (*expression->lex)(expression->context,cc);
	    k_end=(*types->integer_expression)(types->context,cc);
	    if (cc->token==':') {
	      (*expression->lex)(expression->context,cc);
	      if (k_end<lo) lo=k_end;
	      if (k_end>hi) hi=k_end;
	      if (k_start>k_end)
		{ i=k_start; k_start=k_end; k_end=i; }
	      for (i=k_start;i<=k_end;i++) {
		tmps=(*expression->allocate)(expression->context,sizeof(CSwitchCase),FALSE,FALSE);
		tmps->label=lb_entry;
		tmps->val=i;
		tmps->next=header;
		header=tmps;
                if(i==k_end) break; //Do not wrap after I64_MAX.
	      }
	      k_start=k_end;
	    } else
	      (*expression->report)(expression->context,cc,0,"Expecting ':' at ");
	  } else
	    (*expression->report)(expression->context,cc,0,"Expecting ':' at ");
	  break;
	case KW_DFT:
	  if (head.next!=&head) {
	    lb_fwd_case=(*expression->misc)(expression->context,cc,CMT_LABEL);
	    tmpi_jmp=PrsEmit(expression,cc,IC_JMP,lb_fwd_case,0);//In case fall-thru
	  }
	  (*expression->lex)(expression->context,cc);
	  PrsEmit(expression,cc,IC_LABEL,lb_dft,0);
	  if (cc->token==':')
	    (*expression->lex)(expression->context,cc);
	  else
	    (*expression->report)(expression->context,cc,0,"Expecting ':' at ");
	  if (head.next!=&head) {
	    tmpss=head.next;
	    while (tmpss!=&head) {
	      if (tmpss->lb_start)
		PrsEmit(expression,cc,IC_SUB_CALL,tmpss->lb_start,0);
	      tmpss=tmpss->next;
	    }
	    PrsEmit(expression,cc,IC_LABEL,lb_fwd_case,0);
	  }
	  dft_found=TRUE;
	  break;
	default:
	  PrsStmtCore(services,cc,try_cnt,head.last->lb_break);
      }
    }
sw_sub_end:
    tmpss=head.last;
    PrsEmit(expression,cc,IC_LABEL,tmpss->lb_break,0);
    if (tmpss==&head) {
      if (cc->token!='}')
	(*expression->report)(expression->context,cc,0,"Missing '}' at ");
      (*expression->lex)(expression->context,cc);
      break;
    } else {
      PrsQueueRemove(tmpss);
      (*declarations->release)(declarations->context,tmpss);
      if (PrsKeyWord(cc)!=KW_END)
	(*expression->report)(expression->context,cc,0,"Missing 'end' at ");
      if ((*expression->lex)(expression->context,cc)==':')
	(*expression->lex)(expression->context,cc);
      else
	(*expression->report)(expression->context,cc,0,"Expecting ':' at ");
    }
  }
  if (!dft_found)
    PrsEmit(expression,cc,IC_LABEL,lb_dft,0);

  if (0<lo<=16)
    lo=0;
  range=hi-lo+1;
  if (lo>hi || !(0<range<=0xFFFF))
    (*expression->report)(expression->context,cc,0,"switch range error at ");
  jmp_table=(*expression->allocate)(expression->context,(sizeof(CCodeMisc *)*range+0x1FF)&~0x1FF,FALSE,FALSE);
  for(i=0;i<range;i++) jmp_table[i]=lb_dft;
  tmpi_sub->ic_data=lo;
  tmpi_cmp->ic_data=range;
  tmps=header;
  while (tmps) {
    tmps1=tmps->next;
    if (jmp_table[tmps->val-lo]!=lb_dft)
      (*expression->report)(expression->context,cc,0,"Duplicate case at ");
    else
      jmp_table[tmps->val-lo]=tmps->label;
    (*declarations->release)(declarations->context,tmps);
    tmps=tmps1;
  }
  mc_jt->dft=lb_dft;
  mc_jt->jmp_table=jmp_table;
  mc_jt->range=range;
}

U0 PrsNoWarnCore(CPrsStatementServices *services,CCmpCtrl *cc)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CMemberLst *tmpm;
  while (cc->token==TK_IDENT) {
    if (!(tmpm=cc->local_var_entry))
      (*expression->report)(expression->context,cc,0,"Expecting local var at ");
    tmpm->flags|=MLF_NO_UNUSED_WARN;
    if ((*expression->lex)(expression->context,cc)==',')
      (*expression->lex)(expression->context,cc);
    else if (cc->token!=';')
      (*expression->report)(expression->context,cc,0,"Expecting ',' at ");
  }
}

U0 PrsStreamBlkCore(CPrsStatementServices *services,CCmpCtrl *cc)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CLexHashTableContext *htc=(*expression->allocate)(expression->context,sizeof(CLexHashTableContext),FALSE,FALSE);
  CStreamBlk *tmpe=(*expression->allocate)(expression->context,sizeof(CStreamBlk),FALSE,FALSE);
  tmpe->body=(*expression->duplicate)(expression->context,"");
  PrsQueueInsert(tmpe,cc->last_stream_blk);
  (*expression->push)(expression->context,cc);
  PrsQueueInit(&cc->coc.coc_next_misc);

  (*globals->initializers->copy)(globals->initializers->context,htc,&cc->htc,sizeof(CLexHashTableContext));
  htc->old_flags=cc->flags;
  cc->htc.next=htc;
  cc->htc.fun=cc->htc.local_var_lst=NULL;
  cc->htc.define_hash_table=cc->htc.hash_table_lst=
	cc->htc.glbl_hash_table=cc->htc.local_hash_table=(*services->task_symbols)(services->context);
  cc->flags=cc->flags & ~(CCF_ASM_EXPRESSIONS|CCF_AOT_COMPILE) | CCF_EXE_BLK;
  if (cc->token=='{')
    (*expression->lex)(expression->context,cc);
  else
    (*expression->report)(expression->context,cc,0,"Missing '}' at ");
  while (cc->token && cc->token!='}')
    (*services->execute_line)(services->context,cc);

  (*globals->initializers->copy)(globals->initializers->context,&cc->htc,htc,sizeof(CLexHashTableContext));
  cc->flags=cc->flags&~CCF_EXE_BLK |
	htc->old_flags & (CCF_ASM_EXPRESSIONS|CCF_EXE_BLK|CCF_AOT_COMPILE);
  (*declarations->release)(declarations->context,htc);
  (*expression->pop)(expression->context,cc);
  PrsQueueRemove(tmpe);
  if (*tmpe->body)
    (*services->include)(services->context,cc,"StreamBlk",tmpe->body,FALSE);
  else
    (*declarations->release)(declarations->context,tmpe->body);
  (*declarations->release)(declarations->context,tmpe);
  (*expression->lex)(expression->context,cc); //Skip '}'
}

U0 PrsI386TryCallCore(CPrsStatementServices *services,CCmpCtrl *cc,CHashFun *fun,Bool begin=TRUE)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  //Native calls use the ordinary typed call context and explicit result disposal.
  if(begin) PrsEmit(expression,cc,IC_CALL_START,fun,0);
  if(Bt(&fun->flags,Cf_EXTERN)) {
    cc->abs_cnts.externs++;
    if(fun->type&HTF_IMPORT) PrsEmit(expression,cc,IC_CALL_IMPORT,fun,fun->return_class);
    else PrsEmit(expression,cc,IC_CALL_EXTERN,fun,fun->return_class);
  } else PrsEmit(expression,cc,IC_CALL,fun->exe_addr,fun->return_class);
  PrsEmit(expression,cc,IC_ADD_RSP1,fun->arg_cnt*8,fun->return_class);
  PrsEmit(expression,cc,IC_CALL_END,fun,fun->return_class);
  PrsEmit(expression,cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);
}

U0 PrsTryBlkCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  CCodeMisc	*lb_catch,*lb_done,*lb_untry;
  CHashClass	*tmpc=expression->types[RT_PTR];
  CHashFun	*tmp_try=HashFind("SysTry",cc->htc.hash_table_lst,HTT_FUN),
	*tmp_untry=HashFind("SysUntry",cc->htc.hash_table_lst,HTT_FUN);

  if (!tmp_try || !tmp_untry)
    (*expression->report)(expression->context,cc,0,"Missing header for SysTry() and SysUntry() at ");

  cc->flags|=CCF_NO_REG_OPT; //TODO:Currently no reg vars in funs with try/catch

  lb_catch=(*expression->misc)(expression->context,cc,CMT_LABEL);
  lb_done =(*expression->misc)(expression->context,cc,CMT_LABEL);
  lb_untry=(*expression->misc)(expression->context,cc,CMT_LABEL);

  if(cc->flags&CCF_TARGET_I386) {
    PrsEmit(expression,cc,IC_CALL_START,tmp_try,0);
    PrsEmit(expression,cc,IC_GET_LABEL,lb_untry,tmpc,ICF_PUSH_RES);
    PrsEmit(expression,cc,IC_GET_LABEL,lb_catch,tmpc,ICF_PUSH_RES);
    PrsI386TryCallCore(services,cc,tmp_try,FALSE);
  } else {
  PrsEmit(expression,cc,IC_CALL_START,0,0);
  PrsEmit(expression,cc,IC_GET_LABEL,lb_untry,tmpc,ICF_PUSH_RES);
  PrsEmit(expression,cc,IC_GET_LABEL,lb_catch,tmpc,ICF_PUSH_RES);
  if (Bt(&tmp_try->flags,Cf_EXTERN)) {
    cc->abs_cnts.externs++;
    if (cc->flags&CCF_AOT_COMPILE)
      PrsEmit(expression,cc,IC_CALL_IMPORT,tmp_try,tmpc);
    else
      PrsEmit(expression,cc,IC_CALL_INDIRECT2,&tmp_try->exe_addr,tmpc);
  } else
    PrsEmit(expression,cc,IC_CALL,tmp_try->exe_addr,tmpc);
  if ((Bt(&tmp_try->flags,Ff_RET1) ||
	Bt(&tmp_try->flags,Ff_ARGPOP)) && !Bt(&tmp_try->flags,Ff_NOARGPOP))
    PrsEmit(expression,cc,IC_ADD_RSP1,16,tmpc);
  else
    PrsEmit(expression,cc,IC_ADD_RSP,16,tmpc);
  PrsEmit(expression,cc,IC_CALL_END,0,tmpc);
  PrsEmit(expression,cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);

  }

  PrsStmtCore(services,cc,try_cnt+1);

  PrsEmit(expression,cc,IC_LABEL,lb_untry,0);
  if(cc->flags&CCF_TARGET_I386) PrsI386TryCallCore(services,cc,tmp_untry);
  else {
  PrsEmit(expression,cc,IC_CALL_START,0,0);
  if (Bt(&tmp_untry->flags,Cf_EXTERN)) {
    cc->abs_cnts.externs++;
    if (cc->flags&CCF_AOT_COMPILE)
      PrsEmit(expression,cc,IC_CALL_IMPORT,tmp_untry,tmpc);
    else
      PrsEmit(expression,cc,IC_CALL_INDIRECT2,&tmp_untry->exe_addr,tmpc);
  } else
    PrsEmit(expression,cc,IC_CALL,tmp_untry->exe_addr,tmpc);
  PrsEmit(expression,cc,IC_CALL_END,0,tmpc);
  PrsEmit(expression,cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);

  }

  PrsEmit(expression,cc,IC_JMP,lb_done,0);

  if (PrsKeyWord(cc)!=KW_CATCH)
    (*expression->report)(expression->context,cc,0,"Missing 'catch' at");

  (*expression->lex)(expression->context,cc);
  PrsEmit(expression,cc,IC_LABEL,lb_catch,0);
  PrsStmtCore(services,cc,try_cnt+1);
  PrsEmit(expression,cc,IC_RET,0,tmpc);
  PrsEmit(expression,cc,IC_LABEL,lb_done,0);
}

Bool PrsStmtCore(CPrsStatementServices *services,CCmpCtrl *cc,I64 try_cnt=0,
  CCodeMisc *lb_break=NULL,I64 cmp_flags=CMPF_PRS_SEMICOLON)
{
  CPrsGlobalServices *globals=services->globals;
  CPrsDeclarationServices *declarations=globals->symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  I64 i,fsp_flags=0;
  CHashExport *tmpex;
  CCodeMisc *g_lb;
  U8 *import_name;
  CHashFun *tmp_untry;
  CAOT *tmpaot;
  if(services->stack_check) (*services->stack_check)(services->context,cc);
  if (cmp_flags&CMPF_ONE_ASM_INS) {
    if (cc->flags&CCF_AOT_COMPILE || cc->aot_depth)
      (*services->assembly)(services->context,cc,CMPF_ONE_ASM_INS);
    else if (tmpaot=(*services->join)(services->context,cc,CMPF_ASM_BLK|CMPF_ONE_ASM_INS))
      (*services->fix_assembly)(services->context,cc,tmpaot);
    fsp_flags=FSF_ASM;
  } else
    while (TRUE) {
      while (cc->token==',')
	(*expression->lex)(expression->context,cc);
      if (cc->token=='{') {
	(*expression->lex)(expression->context,cc);
	while (cc->token!='}' && cc->token!=TK_EOF)
	  PrsStmtCore(services,cc,try_cnt,lb_break);
	if (cc->lex_include_stk==cc->fun_lex_file)
	  cc->max_line=cc->lex_include_stk->line_num;
	if ((*expression->lex)(expression->context,cc)!=',') goto sm_done;
      } else if (cc->token==';') {
	if (cmp_flags&CMPF_PRS_SEMICOLON)
	  (*expression->lex)(expression->context,cc);
	if (cc->token!=',') goto sm_done;
      } else {
	if (cc->token==TK_IDENT) {
	  if (tmpex=cc->hash_entry) {
	    if (tmpex->type & HTT_KEYWORD) {
	      i=tmpex(CHashGeneric *)->user_data0;
	      switch [i] {
		case KW_KWS_NUM-1: //nobound switch
		default: //A keyword that is not valid here is just a symbol.
		  goto sm_not_keyword_afterall;
		start:
		  case KW_ASM:
		    if (cc->htc.fun) {
		      if (tmpaot=(*services->join)(services->context,cc,CMPF_ASM_BLK))
			PrsEmit(expression,cc,IC_ASM,tmpaot,0);
		      (*expression->lex)(expression->context,cc); //Skip '}' of asm{}
		    } else {
		      if (cc->flags&CCF_AOT_COMPILE || cc->aot_depth) {
			(*expression->lex)(expression->context,cc);
			(*services->assembly)(services->context,cc,0);
			if (cc->flags&CCF_AOT_COMPILE && cc->aot_depth==1)
			  (*expression->lex)(expression->context,cc); //Skip '}' of asm{}
		      } else {
			if (tmpaot=(*services->join)(services->context,cc,CMPF_ASM_BLK))
			  (*services->fix_assembly)(services->context,cc,tmpaot);
			(*expression->lex)(expression->context,cc); //Skip '}' of asm{}
		      }
		      fsp_flags=FSF_ASM;
		    }
		    break;
		  start:
		    (*expression->lex)(expression->context,cc);
		    case KW_LOCK:
		      cc->lock_cnt++;
		      PrsStmtCore(services,cc,try_cnt);
		      cc->lock_cnt--;
		      break;
		    case KW_TRY:
		      PrsTryBlkCore(services,cc,try_cnt);
		      break;
		    case KW_IF:
		      PrsIfCore(services,cc,try_cnt,lb_break);
		      break;
		    case KW_FOR:
		      PrsForCore(services,cc,try_cnt);
		      break;
		    case KW_WHILE:
		      PrsWhileCore(services,cc,try_cnt);
		      break;
		    case KW_DO:
		      PrsDoWhileCore(services,cc,try_cnt);
		      break;
		    case KW_SWITCH:
		      PrsSwitchCore(services,cc,try_cnt);
		      break;
		  end:
		end:
		  if (cc->token!=',') goto sm_done;
		  break;
		start:
		  if (cc->htc.fun)
		    (*expression->report)(expression->context,cc,0,"Not allowed in fun");
		  (*expression->lex)(expression->context,cc);
		  case KW__EXTERN:
		    if (Bt(&cc->opts,OPTf_EXTERNS_TO_IMPORTS))
		      goto sm_underscore_import;
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & HTT_EXPORT_SYS_SYM))
		      (*expression->report)(expression->context,cc,0,"Expecting system sym at ");
		    if (*cc->cur_str=='_')
		      fsp_flags|=FSF__;
		    i=tmpex->val;
		    (*expression->lex)(expression->context,cc);
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      (*expression->report)(expression->context,cc,0,"Expecting type at ");
		    (*expression->lex)(expression->context,cc);
		    PrsGlblVarLstCore(globals,cc,PRS0__EXTERN|PRS1_NULL,tmpex,i,fsp_flags);
		    break;
		  case KW__IMPORT:
sm_underscore_import:
		    if (cc->token!=TK_IDENT)
		      (*expression->report)(expression->context,cc,0,"Expecting system sym at ");
		    if (*cc->cur_str=='_')
		      fsp_flags|=FSF__;
		    import_name=cc->cur_str;
		    cc->cur_str=0;
		    if ((*expression->lex)(expression->context,cc)!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      (*expression->report)(expression->context,cc,0,"Expecting type at ");
		    (*expression->lex)(expression->context,cc);
		    PrsGlblVarLstCore(globals,cc,PRS0__IMPORT|PRS1_NULL,tmpex,
			  import_name,fsp_flags);
		    (*declarations->release)(declarations->context,import_name);
		    break;
		  case KW_EXTERN:
		    if (cc->token!=TK_IDENT)
		      (*expression->report)(expression->context,cc,0,"Expecting type at ");
		    tmpex=cc->hash_entry;
		    i=PrsKeyWord(cc);
		    if (i==KW_CLASS||i==KW_UNION) {
		      (*expression->lex)(expression->context,cc);
		      (*types->class_join)(types->context,cc,i,fsp_flags,TRUE);
		      fsp_flags&=FSF_ASM;
		      goto sm_semicolon;
		    }
		    if (!tmpex ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      (*expression->report)(expression->context,cc,0,"Expecting type at ");
		    if (Bt(&cc->opts,OPTf_EXTERNS_TO_IMPORTS))
		      goto sm_import;
		    (*expression->lex)(expression->context,cc);
		    PrsGlblVarLstCore(globals,cc,PRS0_EXTERN|PRS1_NULL,tmpex,0,fsp_flags);
		    break;
		  case KW_IMPORT:
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      (*expression->report)(expression->context,cc,0,"Expecting type at ");
sm_import:
		    (*expression->lex)(expression->context,cc);
		    PrsGlblVarLstCore(globals,cc,PRS0_IMPORT|PRS1_NULL,tmpex,0,fsp_flags);
		    break;
		  case KW__INTERN:
		    i=(*types->integer_expression)(types->context,cc);
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      (*expression->report)(expression->context,cc,0,"Expecting type at ");
		    (*expression->lex)(expression->context,cc);
		    PrsGlblVarLstCore(globals,cc,PRS0__INTERN|PRS1_NULL,tmpex,i,fsp_flags);
		    break;
		end:
		  fsp_flags&=FSF_ASM;
		  break;
		start:
		  case KW_STATIC:
		    fsp_flags=FSF_STATIC|fsp_flags&FSF_ASM;
		    break;
		  case KW_INTERRUPT:
		    fsp_flags=FSF_INTERRUPT|FSF_NOARGPOP|
			  fsp_flags&(FSG_FUN_FLAGS2|FSF_ASM);
		    break;
		  case KW_HASERRCODE:
		    fsp_flags=FSF_HASERRCODE|fsp_flags&(FSG_FUN_FLAGS2|FSF_ASM);
		    break;
		  case KW_ARGPOP:
		    fsp_flags=FSF_ARGPOP|fsp_flags&(FSG_FUN_FLAGS2|FSF_ASM);
		    break;
		  case KW_NOARGPOP:
		    fsp_flags=FSF_NOARGPOP|fsp_flags&(FSG_FUN_FLAGS2|FSF_ASM);
		    break;
		  case KW_PUBLIC:
		    fsp_flags=FSF_PUBLIC|fsp_flags&(FSG_FUN_FLAGS2|FSF_ASM);
		    break;
		end:
		  (*expression->lex)(expression->context,cc);
		  break;
		case KW_RETURN:
		  if (!cc->htc.fun)
		    (*expression->report)(expression->context,cc,0,"Not in fun.  Can't return a val ");
		  if (try_cnt) {
		    tmp_untry=HashFind("SysUntry",
			  cc->htc.hash_table_lst,HTT_FUN);
		    for (i=0;i<try_cnt;i++) {
		      if(cc->flags&CCF_TARGET_I386) PrsI386TryCallCore(services,cc,tmp_untry);
		      else if (Bt(&tmp_untry->flags,Cf_EXTERN)) {
			cc->abs_cnts.externs++;
			if (cc->flags&CCF_AOT_COMPILE)
			  PrsEmit(expression,cc,IC_CALL_IMPORT,
				tmp_untry,expression->types[RT_PTR]);
			else
			  PrsEmit(expression,cc,IC_CALL_INDIRECT2,
				&tmp_untry->exe_addr,
				expression->types[RT_PTR]);
		      } else
			PrsEmit(expression,cc,IC_CALL,tmp_untry->exe_addr,
			      expression->types[RT_PTR]);
		    }
		  }
		  if ((*expression->lex)(expression->context,cc)!=';') {
		    if (!cc->htc.fun->return_class->size)
		      (*expression->report)(expression->context,cc,1,"Function should NOT return val ");
		    if (!(*expression->expression)(expression->context,cc,NULL,FALSE,NULL))
		      throw('Compiler');
		    PrsEmit(expression,cc,IC_RETURN_VAL,0,cc->htc.fun->return_class);
		    cc->flags|=CCF_HAS_RETURN;
		  } else if (cc->htc.fun->return_class->size)
		    (*expression->report)(expression->context,cc,1,"Function should return val ");
		  PrsEmit(expression,cc,IC_JMP,cc->lb_leave,0);
		  goto sm_semicolon;
		case KW_GOTO:
		  if ((*expression->lex)(expression->context,cc)!=TK_IDENT)
		    (*expression->report)(expression->context,cc,0,"Expecting identifier at ");
		  if (!(g_lb=COCGoToLabelFind(cc,cc->cur_str))) {
		    g_lb=(*expression->misc)(expression->context,cc,CMT_GOTO_LABEL);
		    g_lb->str=cc->cur_str;
		    cc->cur_str=NULL;
		  }
		  g_lb->use_cnt++;
		  PrsEmit(expression,cc,IC_JMP,g_lb,0);
		  (*expression->lex)(expression->context,cc);
		  goto sm_semicolon;
		case KW_BREAK:
		  (*expression->lex)(expression->context,cc);
		  if (!lb_break)
		    (*expression->report)(expression->context,cc,0,"'break' not allowed\n");
		  PrsEmit(expression,cc,IC_JMP,lb_break,0);
		  goto sm_semicolon;
		case KW_NO_WARN:
		  (*expression->lex)(expression->context,cc);
		  PrsNoWarnCore(services,cc);
		  goto sm_semicolon;
		case KW_UNION:
		case KW_CLASS:
		  (*expression->lex)(expression->context,cc);
		  tmpex=(*types->class_join)(types->context,cc,i,fsp_flags,FALSE);
		  if (!cc->htc.fun && cc->token!=';') {
		    PrsGlblVarLstCore(globals,cc,PRS0_NULL|PRS1_NULL,tmpex,0,fsp_flags);
		    fsp_flags&=FSF_ASM;
		    break;
		  } else {
		    fsp_flags&=FSF_ASM;
		    goto sm_semicolon;
		  }
	      }
	    } else {//Ident, found in hash table, not keyword
sm_not_keyword_afterall:
	      if (tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)) {
		if (cc->htc.fun) {
		  if (fsp_flags&FSF_STATIC)
		    PrsVarLstCore(declarations,cc,cc->htc.fun,PRS0_NULL|PRS1_STATIC_LOCAL_VAR);
		  else
		    PrsVarLstCore(declarations,cc,cc->htc.fun,PRS0_NULL|PRS1_LOCAL_VAR);
		  if (cc->token=='}') goto sm_done;
		} else {
		  (*expression->lex)(expression->context,cc);
		  PrsGlblVarLstCore(globals,cc,PRS0_NULL|PRS1_NULL,tmpex,0,fsp_flags);
		}
	      } else {
		if (tmpex->type & (HTT_OPCODE|HTT_ASM_KEYWORD)) {
		  if (cc->htc.fun) {
		    if (tmpaot=(*services->join)(services->context,cc,CMPF_ASM_BLK|CMPF_ONE_ASM_INS))
		      PrsEmit(expression,cc,IC_ASM,tmpaot,0);
		  } else
		    (*expression->report)(expression->context,cc,0,"Use Asm Blk at ");
		  if (cc->token!=',') goto sm_done;
		} else
		  goto sm_prs_exp;
	      }
	      fsp_flags&=FSF_ASM;
	    }
	  } else {//Ident, not in hash table
	    if (cc->local_var_entry)
	      goto sm_prs_exp;
	    if (!(g_lb=COCGoToLabelFind(cc,cc->cur_str))) {
	      g_lb=(*expression->misc)(expression->context,cc,CMT_GOTO_LABEL);
	      g_lb->str=cc->cur_str;
	      cc->cur_str=NULL;
	    } else if (g_lb->flags&CMF_DEFINED)
	      (*expression->report)(expression->context,cc,0,"Duplicate goto label at ");
	    g_lb->flags|=CMF_DEFINED;
	    PrsEmit(expression,cc,IC_LABEL,g_lb,0);
	    if ((*expression->lex)(expression->context,cc)==':') //skip cur_str
	      (*expression->lex)(expression->context,cc); //skip colon
	    else
	      (*expression->report)(expression->context,cc,0,"Undefined identifier at ");
	    if (!cc->htc.fun)
	      (*expression->report)(expression->context,cc,0,"No global labels at ");
	    if (cc->token!=',') goto sm_done;
	  }
	} else if (cc->token==TK_STR||cc->token==TK_CHAR_CONST) {
	  PrsFunCallCore(expression,cc,NULL,FALSE,NULL);
	  goto sm_semicolon;
	} else if (cc->token!=TK_EOF) {//Non-cur_str symbol, num or something
sm_prs_exp:
	  if (!(*expression->expression)(expression->context,cc,NULL,TRUE,NULL))
	    throw('Compiler');
sm_semicolon:
	  if (cmp_flags&CMPF_PRS_SEMICOLON) {
	    if (cc->token==';')
	      (*expression->lex)(expression->context,cc);
	    else if (cc->token!=',')
	      (*expression->report)(expression->context,cc,0,"Missing ';' at");
	  }
	  if (cc->token!=',') goto sm_done;
	} else
	  goto sm_done; //TK_EOF
      }
    }
sm_done:
  return fsp_flags&FSF_ASM;
}
