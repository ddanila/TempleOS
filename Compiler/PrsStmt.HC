#include "/Compiler/PrsSymbolCore.HC"
CHashClass *PrsHostClassNew(U8 *context) { return PrsClassNew; }
CHashFun *PrsHostFunNew(U8 *context) { return PrsFunNew; }
CHash *PrsHostSingleFind(U8 *context,U8 *name,CHashTable *table,I64 mask)
{ return HashSingleTableFind(name,table,mask); }
U0 PrsHostClassMembersDelete(U8 *context,CHashClass *symbol) { ClassMemberLstDel(symbol); }
U0 PrsHostMembersDelete(U8 *context,CMemberLst *members) { MemberLstDel(members); }
U0 PrsHostSource(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol,I64 line_adjust)
{ HashSrcFileSet(cc,symbol,line_adjust); }
Bool PrsHostOption(U8 *context,I64 index) { return GetOption(index); }
U0 PrsHostSymbolWarning(U8 *context,CCmpCtrl *cc,I64 kind,CHashSrcSym *symbol)
{
  if(kind==0) UnusedExternWarning(cc,symbol);
  else {
    if(kind==1) PrintWarn("Fun Header return mismatch '%s'\n",symbol->str);
    else PrintWarn("Fun header args mismatch '%s'\n",symbol->str);
    cc->warning_cnt++;
  }
}
U0 PrsHostSymbolServices(CPrsSymbolServices *services,CPrsDeclarationServices *declarations)
{
  services->context=0; services->declarations=declarations;
  services->used_mask=REGG_CLOBBERED+REGG_SAVED+REGG_STK_TMP;
  services->clobbered_mask=REGG_CLOBBERED+REGG_STK_TMP;
  services->undefined_function=&UndefinedExtern;
  services->class_new=&PrsHostClassNew; services->fun_new=&PrsHostFunNew;
  services->single_find=&PrsHostSingleFind; services->class_members_delete=&PrsHostClassMembersDelete;
  services->members_delete=&PrsHostMembersDelete; services->source=&PrsHostSource;
  services->option=&PrsHostOption; services->warning=&PrsHostSymbolWarning;
}

CHashClass *PrsClass(CCmpCtrl *cc,I64 keyword,I64 fsp_flags,Bool is_extern)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsSymbolServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostSymbolServices(&services,&declarations);
  return PrsClassCore(&services,cc,keyword,fsp_flags,is_extern);
}

CHashFun *PrsFunJoin(CCmpCtrl *cc,CHashClass *tmp_return,
	U8 *name,I64 fsp_flags)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsSymbolServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostSymbolServices(&services,&declarations);
  return PrsFunJoinCore(&services,cc,tmp_return,name,fsp_flags);
}

extern U0 PrsFun(CCmpCtrl *cc,CHashClass *tmp_return,U8 *name,I64 fsp_flags);

#include "/Compiler/PrsGlobalCore.HC"
U0 PrsHostFunction(U8 *context,CCmpCtrl *cc,CHashClass *return_type,U8 *name,I64 flags)
{ PrsFun(cc,return_type,name,flags); }
U0 PrsHostResolve(U8 *context,CCmpCtrl *cc,U8 *name) { SysSymImportsResolve(name); }
Bool PrsHostSameHeap(U8 *context,U8 *left,U8 *right) { return MHeapCtrl(left)==MHeapCtrl(right); }
U0 PrsHostAliasWarning(U8 *context,CCmpCtrl *cc,CHashSrcSym *symbol)
{ PrintWarn("Unused extern '%s'\n",symbol->str); cc->warning_cnt++; }
U0 PrsHostGlobalServices(CPrsGlobalServices *services,
  CPrsSymbolServices *symbols,CPrsInitializerServices *initializers)
{
  services->context=0; services->symbols=symbols; services->initializers=initializers;
  services->function=&PrsHostFunction; services->resolve=&PrsHostResolve;
  services->same_heap=&PrsHostSameHeap; services->alias_warning=&PrsHostAliasWarning;
}

U0 PrsGlblVarLst(CCmpCtrl *cc,I64 saved_mode,CHashClass *saved_tmpc,
  I64 saved_val,I64 fsp_flags)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&services,&symbols,&initializers);
  PrsGlblVarLstCore(&services,cc,saved_mode,saved_tmpc,saved_val,fsp_flags);
}

#include "/Compiler/PrsFunctionCore.HC"
Bool PrsHostStatement(U8 *context,CCmpCtrl *cc,I64 try_count,CCodeMisc *break_label,I64 flags)
{ return PrsStmt(cc,try_count,break_label,flags); }
U8 *PrsHostCompileFunction(U8 *context,CCmpCtrl *cc,I64 *bytes,CDbgInfo **debug,I64 *type)
{ return COCCompile(cc,bytes,debug,type); }
U0 PrsHostDisassemble(U8 *context,U8 *code,I64 bytes) { Un(code,bytes,64); }
U0 PrsHostMemberWarning(U8 *context,CCmpCtrl *cc,CMemberLst *member,Bool unneeded)
{
  if(unneeded)
    PrintWarn("Unneeded no_warn\n $$LK,\"FL:%s,%d\"$$ '%s' in '%s'\n",
      cc->lex_include_stk->full_name,cc->lex_include_stk->line_num,member->str,cc->htc.fun->str);
  else
    PrintWarn("Unused var\n $$LK,\"FL:%s,%d\"$$ '%s' in '%s'\n",
      cc->lex_include_stk->full_name,cc->lex_include_stk->line_num,member->str,cc->htc.fun->str);
}
U0 PrsHostFunctionServices(CPrsFunctionServices *services,CPrsGlobalServices *globals)
{
  services->context=0; services->globals=globals;
  services->statement=&PrsHostStatement; services->compile=&PrsHostCompileFunction;
  services->disassemble=&PrsHostDisassemble; services->member_warning=&PrsHostMemberWarning;
}

U0 PrsFun(CCmpCtrl *cc,CHashClass *tmp_return,U8 *name,I64 fsp_flags)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices declarations;
  CPrsInitializerServices initializers;
  CPrsSymbolServices symbols;
  CPrsGlobalServices globals;
  CPrsFunctionServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&declarations,&expression,&types);
  PrsHostInitializerServices(&initializers,&declarations);
  PrsHostSymbolServices(&symbols,&declarations);
  PrsHostGlobalServices(&globals,&symbols,&initializers);
  PrsHostFunctionServices(&services,&globals);
  PrsFunCore(&services,cc,tmp_return,name,fsp_flags);
}

U0 PrsIf(CCmpCtrl *cc,I64 try_cnt,CCodeMisc *lb_break)
{
  CCodeMisc *lb,*lb1;
  I64 k;
  if (cc->token!='(')
    LexExcept(cc,"Expecting '(' at ");
  Lex(cc);
  if (!PrsExpression(cc,NULL,FALSE))
    throw('Compiler');
  if (cc->token!=')')
    LexExcept(cc,"Missing ')' at ");
  Lex(cc);
  lb=COCMiscNew(cc,CMT_LABEL);
  ICAdd(cc,IC_BR_ZERO,lb,0);
  PrsStmt(cc,try_cnt,lb_break);
  k=PrsKeyWord(cc);
  if (k==KW_ELSE) {
    Lex(cc);
    lb1=COCMiscNew(cc,CMT_LABEL);
    ICAdd(cc,IC_JMP,lb1,0);
    ICAdd(cc,IC_LABEL,lb,0);
    PrsStmt(cc,try_cnt,lb_break);
    ICAdd(cc,IC_LABEL,lb1,0);
  } else
    ICAdd(cc,IC_LABEL,lb,0);
}

U0 PrsWhile(CCmpCtrl *cc,I64 try_cnt)
{
  CCodeMisc *lb,*lb_done;
  if (cc->token!='(')
    LexExcept(cc,"Expecting '(' at ");
  Lex(cc);
  lb=COCMiscNew(cc,CMT_LABEL);
  ICAdd(cc,IC_LABEL,lb,0);
  if (!PrsExpression(cc,NULL,FALSE))
    throw('Compiler');
  if (cc->token!=')')
    LexExcept(cc,"Missing ')' at ");
  Lex(cc);
  lb_done=COCMiscNew(cc,CMT_LABEL);
  ICAdd(cc,IC_BR_ZERO,lb_done,0);
  PrsStmt(cc,try_cnt,lb_done);
  ICAdd(cc,IC_JMP,lb,0);
  ICAdd(cc,IC_LABEL,lb_done,0);
}

U0 PrsDoWhile(CCmpCtrl *cc,I64 try_cnt)
{
  CCodeMisc *lb,*lb_done;
  lb=COCMiscNew(cc,CMT_LABEL);
  lb_done=COCMiscNew(cc,CMT_LABEL);
  ICAdd(cc,IC_LABEL,lb,0);
  PrsStmt(cc,try_cnt,lb_done);
  if (PrsKeyWord(cc)!=KW_WHILE)
    LexExcept(cc,"Missing 'while' at");
  if (Lex(cc)!='(')
    LexExcept(cc,"Expecting '(' at ");
  Lex(cc);
  if (!PrsExpression(cc,NULL,FALSE))
    throw('Compiler');
  if (cc->token!=')')
    LexExcept(cc,"Missing ')' at ");
  ICAdd(cc,IC_BR_NOT_ZERO,lb,0);
  ICAdd(cc,IC_LABEL,lb_done,0);
  if (Lex(cc)!=';')
    LexExcept(cc,"Missing ';' at");
  Lex(cc);
}

U0 PrsFor(CCmpCtrl *cc,I64 try_cnt)
{
  CCodeCtrl *tmpcbh;
  CCodeMisc *lb,*lb_done;

  if (cc->token!='(')
    LexExcept(cc,"Expecting '(' at ");
  Lex(cc);
  PrsStmt(cc,try_cnt);

  lb=COCMiscNew(cc,CMT_LABEL);
  ICAdd(cc,IC_LABEL,lb,0);
  if (!PrsExpression(cc,NULL,FALSE))
    throw('Compiler');
  lb_done=COCMiscNew(cc,CMT_LABEL);
  ICAdd(cc,IC_BR_ZERO,lb_done,0);
  if (cc->token!=';')
    LexExcept(cc,"Missing ';' at");
  Lex(cc);

  COCPush(cc);
  COCInit(cc);
  if (cc->token!=')')
    PrsStmt(cc,try_cnt,NULL,0);
  COCPush(cc);
  tmpcbh=COCPopNoFree(cc);
  COCPop(cc);
  if (cc->token!=')')
    LexExcept(cc,"Missing ')' at ");
  Lex(cc);

  PrsStmt(cc,try_cnt,lb_done);
  COCAppend(cc,tmpcbh);
  ICAdd(cc,IC_JMP,lb,0);
  ICAdd(cc,IC_LABEL,lb_done,0);
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

U0 PrsSwitch(CCmpCtrl *cc,I64 try_cnt)
{
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
    LexExcept(cc,"Expecting '(' or '[' at ");
  Lex(cc);
  QueInit(&head);

  head.last->lb_break=COCMiscNew(cc,CMT_LABEL);
  head.last->lb_break->use_cnt++;
  lb_dft=COCMiscNew(cc,CMT_LABEL);
  lb_dft->use_cnt++;
  mc_jt=COCMiscNew(cc,CMT_JMP_TABLE);
  mc_jt->begin=COCMiscNew(cc,CMT_LABEL);
  mc_jt->begin->use_cnt++;
  if (!PrsExpression(cc,NULL,FALSE))
    throw('Compiler');
  tmpi_sub=ICAdd(cc,IC_IMM_I64,0,cmp.internal_types[RT_I64]);
  ICAdd(cc,IC_SUB,0,cmp.internal_types[RT_I64]);
  tmpi_cmp=ICAdd(cc,IC_IMM_I64,0,cmp.internal_types[RT_I64]);
  if (nobound) {
    ICAdd(cc,IC_NOBOUND_SWITCH,mc_jt,0);
    if (cc->token!=']')
      LexExcept(cc,"Missing ']' at ");
  } else {
    ICAdd(cc,IC_SWITCH,mc_jt,0);
    if (cc->token!=')')
      LexExcept(cc,"Missing ')' at ");
  }
  if (Lex(cc)!='{')
    LexExcept(cc,"Expecting '{' at ");
  Lex(cc);
  ICAdd(cc,IC_LABEL,mc_jt->begin,0);
  while (TRUE) {
    while (cc->token && cc->token!='}') {
sw_cont:
      switch (PrsKeyWord(cc)) {
	case KW_END:
	  goto sw_sub_end;
	case KW_START:
	  if (Lex(cc)==':')
	    Lex(cc);
	  else
	    LexExcept(cc,"Expecting ':' at ");
	  tmpss=MAlloc(sizeof(CSubSwitch));
	  QueIns(tmpss,head.last);
	  head.last->lb_break=COCMiscNew(cc,CMT_LABEL);
	  head.last->lb_break->use_cnt++;
	  lb_fwd_case=COCMiscNew(cc,CMT_LABEL);
	  tmpi_jmp=ICAdd(cc,IC_JMP,lb_fwd_case,0);

	  tmpss->lb_start=COCMiscNew(cc,CMT_LABEL);
	  tmpi_start=ICAdd(cc,IC_LABEL,tmpss->lb_start,0);
	  while (cc->token && cc->token!='}') {
	    switch (PrsKeyWord(cc)) {
	      case KW_END:
		OptFree(cc,tmpi_jmp);
		goto sw_sub_end;
	      case KW_START:
	      case KW_CASE:
	      case KW_DFT:
		if (cc->coc.coc_head.last==tmpi_start) {
		  OptFree(cc,tmpi_jmp);
		  tmpss->lb_start=NULL;
		} else {
		  ICAdd(cc,IC_RET,0,0);
		  ICAdd(cc,IC_LABEL,lb_fwd_case,0);
		  ICAdd(cc,IC_SUB_CALL,tmpss->lb_start,0);//In case fall-thru
		}
		goto sw_cont;
	      default:
		PrsStmt(cc,try_cnt);
	    }
	  }
	  break;
	case KW_CASE:
	  if (head.next!=&head) {
	    lb_fwd_case=COCMiscNew(cc,CMT_LABEL);
	    tmpi_jmp=ICAdd(cc,IC_JMP,lb_fwd_case,0);//In case fall-thru
	  }
	  Lex(cc);
	  lb_entry=COCMiscNew(cc,CMT_LABEL);
	  ICAdd(cc,IC_LABEL,lb_entry,0);
	  lb_entry->use_cnt++;
	  if (head.next!=&head) {
	    tmpss=head.next;
	    while (tmpss!=&head) {
	      if (tmpss->lb_start)
		ICAdd(cc,IC_SUB_CALL,tmpss->lb_start,0);
	      tmpss=tmpss->next;
	    }
	    ICAdd(cc,IC_LABEL,lb_fwd_case,0);
	  }
	  if (cc->token==':') {
	    if (k_start==I64_MIN)
	      k_start=0;
	    else
	      k_start++;
	  } else
	    k_start=LexExpressionI64(cc);
	  if (k_start<lo) lo=k_start;
	  if (k_start>hi) hi=k_start;
	  if (cc->token==':') {
	    Lex(cc);
	    tmps=MAlloc(sizeof(CSwitchCase));
	    tmps->label=lb_entry;
	    tmps->val=k_start;
	    tmps->next=header;
	    header=tmps;
	  } else if (cc->token==TK_ELLIPSIS) {
	    Lex(cc);
	    k_end=LexExpressionI64(cc);
	    if (cc->token==':') {
	      Lex(cc);
	      if (k_end<lo) lo=k_end;
	      if (k_end>hi) hi=k_end;
	      if (k_start>k_end)
		SwapI64(&k_start,&k_end);
	      for (i=k_start;i<=k_end;i++) {
		tmps=MAlloc(sizeof(CSwitchCase));
		tmps->label=lb_entry;
		tmps->val=i;
		tmps->next=header;
		header=tmps;
	      }
	      k_start=k_end;
	    } else
	      LexExcept(cc,"Expecting ':' at ");
	  } else
	    LexExcept(cc,"Expecting ':' at ");
	  break;
	case KW_DFT:
	  if (head.next!=&head) {
	    lb_fwd_case=COCMiscNew(cc,CMT_LABEL);
	    tmpi_jmp=ICAdd(cc,IC_JMP,lb_fwd_case,0);//In case fall-thru
	  }
	  Lex(cc);
	  ICAdd(cc,IC_LABEL,lb_dft,0);
	  if (cc->token==':')
	    Lex(cc);
	  else
	    LexExcept(cc,"Expecting ':' at ");
	  if (head.next!=&head) {
	    tmpss=head.next;
	    while (tmpss!=&head) {
	      if (tmpss->lb_start)
		ICAdd(cc,IC_SUB_CALL,tmpss->lb_start,0);
	      tmpss=tmpss->next;
	    }
	    ICAdd(cc,IC_LABEL,lb_fwd_case,0);
	  }
	  dft_found=TRUE;
	  break;
	default:
	  PrsStmt(cc,try_cnt,head.last->lb_break);
      }
    }
sw_sub_end:
    tmpss=head.last;
    ICAdd(cc,IC_LABEL,tmpss->lb_break,0);
    if (tmpss==&head) {
      if (cc->token!='}')
	LexExcept(cc,"Missing '}' at ");
      Lex(cc);
      break;
    } else {
      QueRem(tmpss);
      Free(tmpss);
      if (PrsKeyWord(cc)!=KW_END)
	LexExcept(cc,"Missing 'end' at ");
      if (Lex(cc)==':')
	Lex(cc);
      else
	LexExcept(cc,"Expecting ':' at ");
    }
  }
  if (!dft_found)
    ICAdd(cc,IC_LABEL,lb_dft,0);

  if (0<lo<=16)
    lo=0;
  range=hi-lo+1;
  if (lo>hi || !(0<range<=0xFFFF))
    LexExcept(cc,"switch range error at ");
  jmp_table=MAlloc((sizeof(CCodeMisc *)*range+0x1FF)&~0x1FF);
  MemSetI64(jmp_table,lb_dft,range);
  tmpi_sub->ic_data=lo;
  tmpi_cmp->ic_data=range;
  tmps=header;
  while (tmps) {
    tmps1=tmps->next;
    if (jmp_table[tmps->val-lo]!=lb_dft)
      LexExcept(cc,"Duplicate case at ");
    else
      jmp_table[tmps->val-lo]=tmps->label;
    Free(tmps);
    tmps=tmps1;
  }
  mc_jt->dft=lb_dft;
  mc_jt->jmp_table=jmp_table;
  mc_jt->range=range;
}

U0 PrsNoWarn(CCmpCtrl *cc)
{
  CMemberLst *tmpm;
  while (cc->token==TK_IDENT) {
    if (!(tmpm=cc->local_var_entry))
      LexExcept(cc,"Expecting local var at ");
    tmpm->flags|=MLF_NO_UNUSED_WARN;
    if (Lex(cc)==',')
      Lex(cc);
    else if (cc->token!=';')
      LexExcept(cc,"Expecting ',' at ");
  }
}

U0 PrsStreamBlk(CCmpCtrl *cc)
{
  CLexHashTableContext *htc=MAlloc(sizeof(CLexHashTableContext));
  CStreamBlk *tmpe=MAlloc(sizeof(CStreamBlk));
  tmpe->body=StrNew("");
  QueIns(tmpe,cc->last_stream_blk);
  COCPush(cc);
  QueInit(&cc->coc.coc_next_misc);

  MemCpy(htc,&cc->htc,sizeof(CLexHashTableContext));
  htc->old_flags=cc->flags;
  cc->htc.next=htc;
  cc->htc.fun=cc->htc.local_var_lst=NULL;
  cc->htc.define_hash_table=cc->htc.hash_table_lst=
	cc->htc.glbl_hash_table=cc->htc.local_hash_table=Fs->hash_table;
  cc->flags=cc->flags & ~(CCF_ASM_EXPRESSIONS|CCF_AOT_COMPILE) | CCF_EXE_BLK;
  if (cc->token=='{')
    Lex(cc);
  else
    LexExcept(cc,"Missing '}' at ");
  while (cc->token && cc->token!='}')
    ExeCmdLine(cc);

  MemCpy(&cc->htc,htc,sizeof(CLexHashTableContext));
  cc->flags=cc->flags&~CCF_EXE_BLK |
	htc->old_flags & (CCF_ASM_EXPRESSIONS|CCF_EXE_BLK|CCF_AOT_COMPILE);
  Free(htc);
  COCPop(cc);
  QueRem(tmpe);
  if (*tmpe->body)
    LexIncludeStr(cc,"StreamBlk",tmpe->body,FALSE);
  else
    Free(tmpe->body);
  Free(tmpe);
  Lex(cc); //Skip '}'
}

U0 PrsI386TryCall(CCmpCtrl *cc,CHashFun *fun,Bool begin=TRUE)
{//Native calls use the ordinary typed call context and explicit result disposal.
  if(begin) ICAdd(cc,IC_CALL_START,fun,0);
  if(Bt(&fun->flags,Cf_EXTERN)) {
    cc->abs_cnts.externs++;
    if(fun->type&HTF_IMPORT) ICAdd(cc,IC_CALL_IMPORT,fun,fun->return_class);
    else ICAdd(cc,IC_CALL_EXTERN,fun,fun->return_class);
  } else ICAdd(cc,IC_CALL,fun->exe_addr,fun->return_class);
  ICAdd(cc,IC_ADD_RSP1,fun->arg_cnt*8,fun->return_class);
  ICAdd(cc,IC_CALL_END,fun,fun->return_class);
  ICAdd(cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);
}

U0 PrsTryBlk(CCmpCtrl *cc,I64 try_cnt)
{
  CCodeMisc	*lb_catch,*lb_done,*lb_untry;
  CHashClass	*tmpc=cmp.internal_types[RT_PTR];
  CHashFun	*tmp_try=HashFind("SysTry",cc->htc.hash_table_lst,HTT_FUN),
	*tmp_untry=HashFind("SysUntry",cc->htc.hash_table_lst,HTT_FUN);

  if (!tmp_try || !tmp_untry)
    LexExcept(cc,"Missing header for SysTry() and SysUntry() at ");

  cc->flags|=CCF_NO_REG_OPT; //TODO:Currently no reg vars in funs with try/catch

  lb_catch=COCMiscNew(cc,CMT_LABEL);
  lb_done =COCMiscNew(cc,CMT_LABEL);
  lb_untry=COCMiscNew(cc,CMT_LABEL);

  if(cc->flags&CCF_TARGET_I386) {
    ICAdd(cc,IC_CALL_START,tmp_try,0);
    ICAdd(cc,IC_GET_LABEL,lb_untry,tmpc,ICF_PUSH_RES);
    ICAdd(cc,IC_GET_LABEL,lb_catch,tmpc,ICF_PUSH_RES);
    PrsI386TryCall(cc,tmp_try,FALSE);
  } else {
  ICAdd(cc,IC_CALL_START,0,0);
  ICAdd(cc,IC_GET_LABEL,lb_untry,tmpc,ICF_PUSH_RES);
  ICAdd(cc,IC_GET_LABEL,lb_catch,tmpc,ICF_PUSH_RES);
  if (Bt(&tmp_try->flags,Cf_EXTERN)) {
    cc->abs_cnts.externs++;
    if (cc->flags&CCF_AOT_COMPILE)
      ICAdd(cc,IC_CALL_IMPORT,tmp_try,tmpc);
    else
      ICAdd(cc,IC_CALL_INDIRECT2,&tmp_try->exe_addr,tmpc);
  } else
    ICAdd(cc,IC_CALL,tmp_try->exe_addr,tmpc);
  if ((Bt(&tmp_try->flags,Ff_RET1) ||
	Bt(&tmp_try->flags,Ff_ARGPOP)) && !Bt(&tmp_try->flags,Ff_NOARGPOP))
    ICAdd(cc,IC_ADD_RSP1,16,tmpc);
  else
    ICAdd(cc,IC_ADD_RSP,16,tmpc);
  ICAdd(cc,IC_CALL_END,0,tmpc);
  ICAdd(cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);

  }

  PrsStmt(cc,try_cnt+1);

  ICAdd(cc,IC_LABEL,lb_untry,0);
  if(cc->flags&CCF_TARGET_I386) PrsI386TryCall(cc,tmp_untry);
  else {
  ICAdd(cc,IC_CALL_START,0,0);
  if (Bt(&tmp_untry->flags,Cf_EXTERN)) {
    cc->abs_cnts.externs++;
    if (cc->flags&CCF_AOT_COMPILE)
      ICAdd(cc,IC_CALL_IMPORT,tmp_untry,tmpc);
    else
      ICAdd(cc,IC_CALL_INDIRECT2,&tmp_untry->exe_addr,tmpc);
  } else
    ICAdd(cc,IC_CALL,tmp_untry->exe_addr,tmpc);
  ICAdd(cc,IC_CALL_END,0,tmpc);
  ICAdd(cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);

  }

  ICAdd(cc,IC_JMP,lb_done,0);

  if (PrsKeyWord(cc)!=KW_CATCH)
    LexExcept(cc,"Missing 'catch' at");

  Lex(cc);
  ICAdd(cc,IC_LABEL,lb_catch,0);
  PrsStmt(cc,try_cnt+1);
  ICAdd(cc,IC_RET,0,tmpc);
  ICAdd(cc,IC_LABEL,lb_done,0);
}

Bool PrsStmt(CCmpCtrl *cc,I64 try_cnt=0,
  CCodeMisc *lb_break=NULL,I64 cmp_flags=CMPF_PRS_SEMICOLON)
{
  I64 i,fsp_flags=0;
  CHashExport *tmpex;
  CCodeMisc *g_lb;
  U8 *import_name;
  CHashFun *tmp_untry;
  CAOT *tmpaot;
  if (cmp_flags&CMPF_ONE_ASM_INS) {
    if (cc->flags&CCF_AOT_COMPILE || cc->aot_depth)
      PrsAsmBlk(cc,CMPF_ONE_ASM_INS);
    else if (tmpaot=CmpJoin(cc,CMPF_ASM_BLK|CMPF_ONE_ASM_INS))
      CmpFixUpJITAsm(cc,tmpaot);
    fsp_flags=FSF_ASM;
  } else
    while (TRUE) {
      while (cc->token==',')
	Lex(cc);
      if (cc->token=='{') {
	Lex(cc);
	while (cc->token!='}' && cc->token!=TK_EOF)
	  PrsStmt(cc,try_cnt,lb_break);
	if (cc->lex_include_stk==cc->fun_lex_file)
	  cc->max_line=cc->lex_include_stk->line_num;
	if (Lex(cc)!=',') goto sm_done;
      } else if (cc->token==';') {
	if (cmp_flags&CMPF_PRS_SEMICOLON)
	  Lex(cc);
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
		      if (tmpaot=CmpJoin(cc,CMPF_ASM_BLK))
			ICAdd(cc,IC_ASM,tmpaot,0);
		      Lex(cc); //Skip '}' of asm{}
		    } else {
		      if (cc->flags&CCF_AOT_COMPILE || cc->aot_depth) {
			Lex(cc);
			PrsAsmBlk(cc,0);
			if (cc->flags&CCF_AOT_COMPILE && cc->aot_depth==1)
			  Lex(cc); //Skip '}' of asm{}
		      } else {
			if (tmpaot=CmpJoin(cc,CMPF_ASM_BLK))
			  CmpFixUpJITAsm(cc,tmpaot);
			Lex(cc); //Skip '}' of asm{}
		      }
		      fsp_flags=FSF_ASM;
		    }
		    break;
		  start:
		    Lex(cc);
		    case KW_LOCK:
		      cc->lock_cnt++;
		      PrsStmt(cc,try_cnt);
		      cc->lock_cnt--;
		      break;
		    case KW_TRY:
		      PrsTryBlk(cc,try_cnt);
		      break;
		    case KW_IF:
		      PrsIf(cc,try_cnt,lb_break);
		      break;
		    case KW_FOR:
		      PrsFor(cc,try_cnt);
		      break;
		    case KW_WHILE:
		      PrsWhile(cc,try_cnt);
		      break;
		    case KW_DO:
		      PrsDoWhile(cc,try_cnt);
		      break;
		    case KW_SWITCH:
		      PrsSwitch(cc,try_cnt);
		      break;
		  end:
		end:
		  if (cc->token!=',') goto sm_done;
		  break;
		start:
		  if (cc->htc.fun)
		    LexExcept(cc,"Not allowed in fun");
		  Lex(cc);
		  case KW__EXTERN:
		    if (Bt(&cc->opts,OPTf_EXTERNS_TO_IMPORTS))
		      goto sm_underscore_import;
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & HTT_EXPORT_SYS_SYM))
		      LexExcept(cc,"Expecting system sym at ");
		    if (*cc->cur_str=='_')
		      fsp_flags|=FSF__;
		    i=tmpex->val;
		    Lex(cc);
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      LexExcept(cc,"Expecting type at ");
		    Lex(cc);
		    PrsGlblVarLst(cc,PRS0__EXTERN|PRS1_NULL,tmpex,i,fsp_flags);
		    break;
		  case KW__IMPORT:
sm_underscore_import:
		    if (cc->token!=TK_IDENT)
		      LexExcept(cc,"Expecting system sym at ");
		    if (*cc->cur_str=='_')
		      fsp_flags|=FSF__;
		    import_name=cc->cur_str;
		    cc->cur_str=0;
		    if (Lex(cc)!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      LexExcept(cc,"Expecting type at ");
		    Lex(cc);
		    PrsGlblVarLst(cc,PRS0__IMPORT|PRS1_NULL,tmpex,
			  import_name,fsp_flags);
		    Free(import_name);
		    break;
		  case KW_EXTERN:
		    if (cc->token!=TK_IDENT)
		      LexExcept(cc,"Expecting type at ");
		    tmpex=cc->hash_entry;
		    i=PrsKeyWord(cc);
		    if (i==KW_CLASS||i==KW_UNION) {
		      Lex(cc);
		      PrsClass(cc,i,fsp_flags,TRUE);
		      fsp_flags&=FSF_ASM;
		      goto sm_semicolon;
		    }
		    if (!tmpex ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      LexExcept(cc,"Expecting type at ");
		    if (Bt(&cc->opts,OPTf_EXTERNS_TO_IMPORTS))
		      goto sm_import;
		    Lex(cc);
		    PrsGlblVarLst(cc,PRS0_EXTERN|PRS1_NULL,tmpex,0,fsp_flags);
		    break;
		  case KW_IMPORT:
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      LexExcept(cc,"Expecting type at ");
sm_import:
		    Lex(cc);
		    PrsGlblVarLst(cc,PRS0_IMPORT|PRS1_NULL,tmpex,0,fsp_flags);
		    break;
		  case KW__INTERN:
		    i=LexExpressionI64(cc);
		    if (cc->token!=TK_IDENT || !(tmpex=cc->hash_entry) ||
			  !(tmpex->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
		      LexExcept(cc,"Expecting type at ");
		    Lex(cc);
		    PrsGlblVarLst(cc,PRS0__INTERN|PRS1_NULL,tmpex,i,fsp_flags);
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
		  Lex(cc);
		  break;
		case KW_RETURN:
		  if (!cc->htc.fun)
		    LexExcept(cc,"Not in fun.  Can't return a val ");
		  if (try_cnt) {
		    tmp_untry=HashFind("SysUntry",
			  cc->htc.hash_table_lst,HTT_FUN);
		    for (i=0;i<try_cnt;i++) {
		      if(cc->flags&CCF_TARGET_I386) PrsI386TryCall(cc,tmp_untry);
		      else if (Bt(&tmp_untry->flags,Cf_EXTERN)) {
			cc->abs_cnts.externs++;
			if (cc->flags&CCF_AOT_COMPILE)
			  ICAdd(cc,IC_CALL_IMPORT,
				tmp_untry,cmp.internal_types[RT_PTR]);
			else
			  ICAdd(cc,IC_CALL_INDIRECT2,
				&tmp_untry->exe_addr,
				cmp.internal_types[RT_PTR]);
		      } else
			ICAdd(cc,IC_CALL,tmp_untry->exe_addr,
			      cmp.internal_types[RT_PTR]);
		    }
		  }
		  if (Lex(cc)!=';') {
		    if (!cc->htc.fun->return_class->size)
		      LexWarn(cc,"Function should NOT return val ");
		    if (!PrsExpression(cc,NULL,FALSE))
		      throw('Compiler');
		    ICAdd(cc,IC_RETURN_VAL,0,cc->htc.fun->return_class);
		    cc->flags|=CCF_HAS_RETURN;
		  } else if (cc->htc.fun->return_class->size)
		    LexWarn(cc,"Function should return val ");
		  ICAdd(cc,IC_JMP,cc->lb_leave,0);
		  goto sm_semicolon;
		case KW_GOTO:
		  if (Lex(cc)!=TK_IDENT)
		    LexExcept(cc,"Expecting identifier at ");
		  if (!(g_lb=COCGoToLabelFind(cc,cc->cur_str))) {
		    g_lb=COCMiscNew(cc,CMT_GOTO_LABEL);
		    g_lb->str=cc->cur_str;
		    cc->cur_str=NULL;
		  }
		  g_lb->use_cnt++;
		  ICAdd(cc,IC_JMP,g_lb,0);
		  Lex(cc);
		  goto sm_semicolon;
		case KW_BREAK:
		  Lex(cc);
		  if (!lb_break)
		    LexExcept(cc,"'break' not allowed\n");
		  ICAdd(cc,IC_JMP,lb_break,0);
		  goto sm_semicolon;
		case KW_NO_WARN:
		  Lex(cc);
		  PrsNoWarn(cc);
		  goto sm_semicolon;
		case KW_UNION:
		case KW_CLASS:
		  Lex(cc);
		  tmpex=PrsClass(cc,i,fsp_flags,FALSE);
		  if (!cc->htc.fun && cc->token!=';') {
		    PrsGlblVarLst(cc,PRS0_NULL|PRS1_NULL,tmpex,0,fsp_flags);
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
		    PrsVarLst(cc,cc->htc.fun,PRS0_NULL|PRS1_STATIC_LOCAL_VAR);
		  else
		    PrsVarLst(cc,cc->htc.fun,PRS0_NULL|PRS1_LOCAL_VAR);
		  if (cc->token=='}') goto sm_done;
		} else {
		  Lex(cc);
		  PrsGlblVarLst(cc,PRS0_NULL|PRS1_NULL,tmpex,0,fsp_flags);
		}
	      } else {
		if (tmpex->type & (HTT_OPCODE|HTT_ASM_KEYWORD)) {
		  if (cc->htc.fun) {
		    if (tmpaot=CmpJoin(cc,CMPF_ASM_BLK|CMPF_ONE_ASM_INS))
		      ICAdd(cc,IC_ASM,tmpaot,0);
		  } else
		    LexExcept(cc,"Use Asm Blk at ");
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
	      g_lb=COCMiscNew(cc,CMT_GOTO_LABEL);
	      g_lb->str=cc->cur_str;
	      cc->cur_str=NULL;
	    } else if (g_lb->flags&CMF_DEFINED)
	      LexExcept(cc,"Duplicate goto label at ");
	    g_lb->flags|=CMF_DEFINED;
	    ICAdd(cc,IC_LABEL,g_lb,0);
	    if (Lex(cc)==':') //skip cur_str
	      Lex(cc); //skip colon
	    else
	      LexExcept(cc,"Undefined identifier at ");
	    if (!cc->htc.fun)
	      LexExcept(cc,"No global labels at ");
	    if (cc->token!=',') goto sm_done;
	  }
	} else if (cc->token==TK_STR||cc->token==TK_CHAR_CONST) {
	  PrsFunCall(cc,NULL,FALSE,NULL);
	  goto sm_semicolon;
	} else if (cc->token!=TK_EOF) {//Non-cur_str symbol, num or something
sm_prs_exp:
	  if (!PrsExpression(cc,NULL,TRUE))
	    throw('Compiler');
sm_semicolon:
	  if (cmp_flags&CMPF_PRS_SEMICOLON) {
	    if (cc->token==';')
	      Lex(cc);
	    else if (cc->token!=',')
	      LexExcept(cc,"Missing ';' at");
	  }
	  if (cc->token!=',') goto sm_done;
	} else
	  goto sm_done; //TK_EOF
      }
    }
sm_done:
  return fsp_flags&FSF_ASM;
}
