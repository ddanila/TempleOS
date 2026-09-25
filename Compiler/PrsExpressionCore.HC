//Shared complete expression parsing; supplied services own effects and failures.
#include "/Compiler/PrsExpression.HH"
CHashClass *PrsClassView(CPrsExpressionServices *services,CHashClass *type)
{
  if(services->class_view) return services->class_view(services->context,type);
  return type;
}
CHashClass *PrsClassFwdView(CPrsExpressionServices *services,CHashClass *type)
{
  type=PrsClassView(services,type);
  while(type->fwd_class) type=PrsClassView(services,type->fwd_class);
  return type;
}
I64 PrsClassViewSize(CPrsExpressionServices *services,CCmpCtrl *cc,CHashClass *type)
{ return CmpTargetSize(cc,PrsClassView(services,type)); }
CIntermediateCode *PrsEmit(CPrsExpressionServices *services,CCmpCtrl *cc,
  I64 op,I64 value,CHashClass *type,I64 flags=0)
{ return (*services->add)(services->context,cc,op,value,type,flags); }

#define PE_UNARY_TERM1		0
#define PE_UNARY_TERM2		1
#define PE_MAYBE_MODIFIERS	2
#define PE_UNARY_MODIFIERS	3
#define PE_DEREFERENCE		4
#define PE_CHECK_BINARY_OPS1	5
#define PE_CHECK_BINARY_OPS2	6
#define PE_DO_UNARY_OP		7
#define PE_DO_BINARY_OP		8
#define PE_POP_HIGHER		9
#define PE_PUSH_LOWER		10
#define PE_POP_ALL1		11
#define PE_POP_ALL2		12

CIntermediateCode *PrsAddOpCore(CPrsExpressionServices *services,CCmpCtrl *cc,I64 stk_op,CHashClass *tmpc)
{
  CIntermediateCode *tmpi=cc->coc.coc_head.last;
  Bool div_sizeof=FALSE;
  switch (stk_op.u16[0]) {
    case IC_ADD:
      if (tmpc->ptr_stars_cnt && !tmpi->ic_class->ptr_stars_cnt &&
	    tmpi->ic_class->raw_type!=RT_F64) {
	PrsEmit(services,cc,IC_SIZEOF,1,services->types[RT_I64]);
	PrsEmit(services,cc,IC_MUL,0,services->types[RT_I64]);
      }
      break;
    case IC_SUB:
      if (tmpc->ptr_stars_cnt && tmpi->ic_class->raw_type!=RT_F64) {
	if (!tmpi->ic_class->ptr_stars_cnt) {
	  PrsEmit(services,cc,IC_SIZEOF,1,services->types[RT_I64]);
	  PrsEmit(services,cc,IC_MUL,0,services->types[RT_I64]);
	} else
	  div_sizeof=TRUE;
      }
      break;
    case IC_AND_AND:
    case IC_OR_OR:
      PrsEmit(services,cc,IC_NOP1,0,services->types[RT_I64]);
      break;
    case IC_ADD_EQU:
    case IC_SUB_EQU:
      if (tmpc->ptr_stars_cnt) {
	PrsEmit(services,cc,IC_SIZEOF,1,services->types[RT_I64]);
	PrsEmit(services,cc,IC_MUL,0,services->types[RT_I64]);
      }
      break;
  }
  tmpi=PrsEmit(services,cc,stk_op,0,tmpc);
  if (stk_op.u8[3]&ECF_HAS_PUSH_CMP) {
    tmpi->ic_flags|=ICF_POP_CMP;
    PrsEmit(services,cc,IC_NOP1,0,services->types[RT_I64]);
    PrsEmit(services,cc,IC_AND_AND,0,services->types[RT_I64],ICF_POP_CMP);
  }
  if (div_sizeof) {
    tmpc--;
    if (PrsClassViewSize(services,cc,tmpc)!=1) {
      PrsEmit(services,cc,IC_IMM_I64,PrsClassViewSize(services,cc,tmpc),services->types[RT_I64]);
      PrsEmit(services,cc,IC_DIV,0,services->types[RT_I64]);
      tmpc=services->types[RT_I64];
    }
  }
  return tmpi;
}

U0 PrsExpression2Core(CPrsExpressionServices *services,CCmpCtrl *cc,I64 *_max_prec,CPrsStk *ps)
{
  I64 i,cur_op,stk_op,state,max_prec=PREC_NULL,unary_pre_prec,paren_prec,
	unary_post_prec,left_prec=PREC_MAX;
  CIntermediateCode *tmpi;
  CHashClass *tmpc;
  CMemberLst *local_var;
  CArrayDim *tmpad=NULL;

  goto pe_unary_term1;
  while (TRUE) {
    switch [state] {
      case PE_UNARY_TERM1:
pe_unary_term1:
	unary_pre_prec=PREC_NULL;
	unary_post_prec=PREC_NULL;
	cc->flags&=~(CCF_PAREN+CCF_PREINC+CCF_PREDEC+CCF_POSTINC+
	      CCF_POSTDEC+CCF_FUN_EXP);
      case PE_UNARY_TERM2:
	state=PrsUnaryTermCore(services,cc,ps,&local_var,&tmpad,
	      &max_prec,&unary_pre_prec,&paren_prec);
	break;
      case PE_UNARY_MODIFIERS:
	state=PrsUnaryModifierCore(services,cc,ps,&local_var,&tmpad,&unary_post_prec);
	break;
      case PE_MAYBE_MODIFIERS:
	if (cc->token=='(') { //Typecast or fun_ptr
	  cc->flags|=CCF_RAX;
	  state=PrsUnaryModifierCore(services,cc,ps,&local_var,&tmpad,&unary_post_prec);
	} else
	  goto pe_check_binary_ops1;
	break;
      case PE_DEREFERENCE:
	if (!(cc->flags&(CCF_PREINC|CCF_PREDEC|CCF_POSTINC|CCF_POSTDEC)))
	  i=IC_DEREF+PREC_UNARY_PRE<<16;
	else {
	  if (cc->flags & CCF_POSTINC)
	    i=IC__PP+PREC_UNARY_POST<<16;
	  else if (cc->flags & CCF_POSTDEC)
	    i=IC__MM+PREC_UNARY_POST<<16;
	  else if (cc->flags & CCF_PREDEC)
	    i=IC_MM_+PREC_UNARY_PRE<<16;
	  else
	    i=IC_PP_+PREC_UNARY_PRE<<16;
	  cc->flags&=~(CCF_PREINC|CCF_PREDEC|CCF_POSTINC|CCF_POSTDEC);
	}
	tmpi=cc->coc.coc_head.last;
	if (cc->flags & (CCF_RAX|CCF_ARRAY)) {
	  if (tmpi->ic_code==IC_DEREF)
	    tmpi->ic_code=i;
	} else {
	  tmpc=PrsClassFwdView(services,tmpi->ic_class-1);
	  PrsEmit(services,cc,i,0,tmpc);
	}
      case PE_CHECK_BINARY_OPS1:
pe_check_binary_ops1:
	if (paren_prec) {
	  if (unary_pre_prec || unary_post_prec) {
	    if (paren_prec<=unary_pre_prec && !unary_post_prec)
	      (*services->report)(services->context,cc,2,0);
	    paren_prec=PREC_NULL;
	  } else if (paren_prec<=PREC_UNARY_PRE+ASSOC_MASK)
	    (*services->report)(services->context,cc,2,0);
	}
	cur_op=services->binary_ops[cc->token];

      case PE_CHECK_BINARY_OPS2:
pe_check_binary_ops2:
	stk_op=PrsPop(ps);
	tmpc=PrsPop(ps);
	if (!(0<stk_op.u8[2]<=PREC_UNARY_PRE+ASSOC_MASK))
	  goto pe_do_binary_op;

      case PE_DO_UNARY_OP:
	if (cur_op.u16[0]==IC_POWER &&
	      stk_op.u16[0]==IC_UNARY_MINUS) {
	  (*services->lex)(services->context,cc); //skip ` op
	  left_prec=cur_op.i8[2];
	  PrsPush(ps,tmpc);
	  PrsPush(ps,stk_op);
	  PrsPush(ps,cc->coc.coc_head.last->ic_class);
	  PrsPush(ps,cur_op);
	  goto pe_unary_term1;
	} else {
	  tmpi=cc->coc.coc_head.last;
	  tmpc=tmpi->ic_class;
	  if (stk_op.u16[0]==IC_DEREF && tmpc->ptr_stars_cnt)
	    tmpc--;
	  else if (stk_op.u16[0]==IC_ADDR) {
	    cc->abs_cnts.c_addres++;
	    if (intermediate_code_table[tmpi->ic_code].type==IST_DEREF)
	      (*services->retire)(services->context,cc,tmpi);
	    tmpc++;
	  }
	  tmpc=PrsClassFwdView(services,tmpc);
	  if (stk_op)
	    PrsEmit(services,cc,stk_op,0,tmpc);
	  goto pe_check_binary_ops2;
	}

      case PE_DO_BINARY_OP:
pe_do_binary_op:
	PrsPush(ps,tmpc);
	PrsPush(ps,stk_op);
	if (!cur_op)
	  goto pe_pop_all1;

	switch (cur_op.u16[0]) {
	  case IC_ADD:
	  case IC_SUB:
	    tmpi=cc->coc.coc_head.last;
	    if (!tmpi->ic_class->ptr_stars_cnt &&
		  tmpi->ic_class->raw_type!=RT_F64) {
	      PrsEmit(services,cc,IC_SIZEOF,1,services->types[RT_I64]);
	      PrsEmit(services,cc,IC_MUL,0,services->types[RT_I64]);
	    }
	    break;
	  case IC_AND_AND:
	  case IC_OR_OR:
	    PrsEmit(services,cc,IC_NOP1,0,services->types[RT_I64]);
	    break;
	}
	if (cc->flags & CCF_FUN_EXP) {
	  ps->ptr2--;
	  cc->flags&=~CCF_FUN_EXP;
	}
	(*services->lex)(services->context,cc); //skip op
	if (paren_prec>PREC_UNARY_PRE+ASSOC_MASK &&
	      paren_prec&~ASSOC_MASK<left_prec&~ASSOC_MASK+
	      paren_prec&ASSOCF_RIGHT &&
	      paren_prec&~ASSOC_MASK<cur_op.u8[2]&~ASSOC_MASK+
	      !(paren_prec&ASSOCF_RIGHT))
	  (*services->report)(services->context,cc,2,0);
	if (cur_op.u8[2]>max_prec)
	  max_prec=cur_op.u8[2];
	left_prec=cur_op.u8[2];
	if (intermediate_code_table[cur_op.u16[0]].type==IST_ASSIGN) {
	  tmpi=cc->coc.coc_head.last;
	  tmpc=PrsClassFwdView(services,tmpi->ic_class);
	  if (intermediate_code_table[tmpi->ic_code].type!=IST_DEREF ||
		!tmpc->ptr_stars_cnt && !Bt(&tmpc->flags,Cf_INTERNAL_TYPE))
	    (*services->report)(services->context,cc,0,"Invalid lval at ");
	  tmpi->ic_code=IC_NOP1; //Important for setting class (pretty sure)
	  cur_op.u8[2]=PREC_ASSIGN|ASSOCF_RIGHT;
	}

      case PE_POP_HIGHER:
pe_pop_higher:
	stk_op=PrsPop(ps); //pop ops of higher prec
	tmpc=PrsPop(ps);
	if (!stk_op)
	  goto pe_push_lower;
	else if (cur_op.u8[2]&~ASSOC_MASK==stk_op.u8[2]&~ASSOC_MASK) {
	  if (cur_op.u8[2]&ASSOCF_RIGHT)
	    goto pe_push_lower;
	} else if (cur_op.u8[2]&~ASSOC_MASK<=stk_op.u8[2]&~ASSOC_MASK)
	  goto pe_push_lower;

	tmpi=PrsAddOpCore(services,cc,stk_op,tmpc);

	if (intermediate_code_table[cur_op.u16[0]].type==IST_CMP &&
	      intermediate_code_table[stk_op.u16[0]].type==IST_CMP) {
	  tmpi->ic_flags|=ICF_PUSH_CMP;
	  PrsEmit(services,cc,IC_NOP1,0,services->types[RT_I64]);
	  PrsEmit(services,cc,IC_PUSH_CMP,0,tmpc);
	  cur_op.u8[3]|=ECF_HAS_PUSH_CMP;
	} else if (cur_op.u16[0]==IC_AND_AND || cur_op.u16[0]==IC_OR_OR)
	  PrsEmit(services,cc,IC_NOP1,0,services->types[RT_I64]);
	goto pe_pop_higher;

      case PE_PUSH_LOWER:
pe_push_lower:
	PrsPush(ps,tmpc);
	PrsPush(ps,stk_op);
	PrsPush(ps,cc->coc.coc_head.last->ic_class);
	PrsPush(ps,cur_op);
	goto pe_unary_term1;

      case PE_POP_ALL1:
pe_pop_all1:
	if (paren_prec>PREC_UNARY_PRE+ASSOC_MASK &&
	      paren_prec&~ASSOC_MASK<=left_prec&~ASSOC_MASK-
	      paren_prec&ASSOCF_LEFT-left_prec&ASSOCF_LEFT)
	  (*services->report)(services->context,cc,2,0);
      case PE_POP_ALL2:
pe_pop_all2:
	stk_op=PrsPop(ps);
	tmpc=PrsPop(ps);
	if (!stk_op.u16[0])
	  goto pe_done;
	PrsAddOpCore(services,cc,stk_op,tmpc);
	goto pe_pop_all2;
    }
  }
pe_done:
  if (_max_prec)
    *_max_prec=max_prec;
}

U0 PrsSizeOfCore(CPrsExpressionServices *services,CCmpCtrl *cc)
{
  CHashClass *tmpc;
  CMemberLst *tmpm;
  CDbgInfo *dbg_info;
  I64 i;
  if (cc->token!=TK_IDENT)
    (*services->report)(services->context,cc,0,"Invalid class at ");
  if (tmpm=cc->local_var_entry) {
    tmpc=tmpm->member_class;
    i=PrsClassViewSize(services,cc,tmpc)*tmpm->dim.total_cnt;
    if ((*services->lex)(services->context,cc)=='.')
      goto pu_sizeof_member;
  } else {
    if (!(tmpc=cc->hash_entry) || !(tmpc->type &
	  (HTT_CLASS|HTT_INTERNAL_TYPE|HTT_GLBL_VAR|
	  HTT_FUN|HTT_EXPORT_SYS_SYM)))
      (*services->report)(services->context,cc,0,"Invalid class at ");
    if (tmpc->type&(HTT_FUN|HTT_EXPORT_SYS_SYM)) {
      if (!(dbg_info=tmpc(CHashFun *)->dbg_info))
	(*services->report)(services->context,cc,0,"Size not defined at ");
      i=dbg_info->body[dbg_info->max_line+1-dbg_info->min_line]
	    -dbg_info->body[0];
      (*services->lex)(services->context,cc);
    } else {
      i=PrsClassViewSize(services,cc,tmpc);
      while ((*services->lex)(services->context,cc)=='.') {
pu_sizeof_member:
	if (!(tmpc->type & (HTT_CLASS|HTT_GLBL_VAR)))
	  (*services->report)(services->context,cc,0,"Invalid class at ");
	else if (tmpc->type & HTT_GLBL_VAR)
	  tmpc=tmpc(CHashGlblVar *)->var_class;
	if ((*services->lex)(services->context,cc)!=TK_IDENT || !(tmpm=MemberFind(cc->cur_str,PrsClassView(services,tmpc))))
	  (*services->report)(services->context,cc,0,"Invalid member at ");
	else if (cc->local_var_entry)
	  cc->local_var_entry->use_cnt--;
	tmpc=tmpm->member_class;
//Probably others like this:
	#assert offset(CHashClass.size)==offset(CHashGlblVar.size)
	i=PrsClassViewSize(services,cc,tmpc)*tmpm->dim.total_cnt;
      }
    }
  }
  if (cc->token=='*') {
    while ((*services->lex)(services->context,cc)=='*');
    if (cc->flags&CCF_TARGET_I386) i=4;
    else i=sizeof(U8 *);
  }
  PrsEmit(services,cc,IC_IMM_I64,i,services->types[RT_I64]);
}

U0 PrsOffsetOfCore(CPrsExpressionServices *services,CCmpCtrl *cc)
{
  CHashClass *tmpc;
  CMemberLst *tmpm;
  I64 i;
  if (cc->token!=TK_IDENT)
    (*services->report)(services->context,cc,0,"Invalid class at ");
  if (tmpm=cc->local_var_entry)
    tmpc=tmpm->member_class;
  else {
    tmpc=cc->hash_entry;
    if (!tmpc || !(tmpc->type & (HTT_CLASS|HTT_GLBL_VAR)))
      (*services->report)(services->context,cc,0,"Invalid class at ");
    else if (tmpc->type & HTT_GLBL_VAR)
      tmpc=tmpc(CHashGlblVar *)->var_class;
  }
  if ((*services->lex)(services->context,cc)!='.')
    (*services->report)(services->context,cc,0,"Expecting '.' at ");
  i=0;
  do {
    if ((*services->lex)(services->context,cc)!=TK_IDENT || !(tmpm=MemberFind(cc->cur_str,PrsClassView(services,tmpc))))
      (*services->report)(services->context,cc,0,"Invalid member at ");
    else if (cc->local_var_entry)
      cc->local_var_entry->use_cnt--;
    i+=tmpm->offset;
    tmpc=tmpm->member_class;
  } while ((*services->lex)(services->context,cc)=='.');
  PrsEmit(services,cc,IC_IMM_I64,i,services->types[RT_I64]);
}

I64 PrsFunCallCore(CPrsExpressionServices *services,CCmpCtrl *cc,CPrsStk *ps,Bool indirect,CHashFun *tmpf)
{
  I64 i,argc_cnt,dft_val;
  Bool is_first_arg=TRUE,needs_right_paren,is_print,is_putchars,
	is_template_fun;
  CHashClass *tmpc2,*last_class=NULL;
  CMemberLst *tmpm;
  CCodeCtrl *tmpcbh,*tmpcbh1;
  CCodeMisc *cm;
  CIntermediateCode *tmpi;

  if (!tmpf) {
    if (cc->token==TK_CHAR_CONST) {
      if (!(tmpf=HashFind("PutChars",cc->htc.hash_table_lst,HTT_FUN)))
	(*services->report)(services->context,cc,0,"Missing header for Print() and PutChars() at ");
      if (!cc->cur_i64) //empty char signals PutChars with variable
	(*services->lex)(services->context,cc);
      is_print=FALSE;
      is_putchars=TRUE;
    } else {
      if (!(tmpf=HashFind("Print",cc->htc.hash_table_lst,HTT_FUN)))
	(*services->report)(services->context,cc,0,"Missing header for Print() and PutChars() at ");
      if (!*cc->cur_str) //empty string signals Print with variable fmt_str
	(*services->lex)(services->context,cc);
      is_putchars=FALSE;
      is_print=TRUE;
    }
  } else {
    is_print=FALSE;
    is_putchars=FALSE;
  }

  if (Bt(&tmpf->flags,Ff_INTERNAL)&& IC_SQR<=tmpf->exe_addr<=IC_ATAN)
    is_template_fun=TRUE;
  else
    is_template_fun=FALSE;

  if (indirect) {
    tmpc2=services->types[RT_PTR];
    if (cc->flags&CCF_TARGET_I386) tmpc2=services->types[RT_U8]+1;
    if (!(cc->flags & (CCF_RAX | CCF_ARRAY)))
      PrsEmit(services,cc,IC_DEREF,0,tmpc2);
    cc->coc.coc_head.last->ic_class=tmpc2;
    PrsEmit(services,cc,IC_SET_RAX,0,tmpc2);
    PrsEmit(services,cc,IC_NOP2,1,tmpc2); //balance the books
  }
  (*services->push)(services->context,cc);
  tmpcbh=cc->coc.coc_next;
  cc->coc.coc_next=NULL;
  i=tmpf->arg_cnt;
  tmpm=tmpf->member_lst_and_root;
  argc_cnt=0;
  if (cc->token=='(') {
    (*services->lex)(services->context,cc);
    needs_right_paren=TRUE;
  } else
    needs_right_paren=FALSE;
  while (i--) {
    (*services->init)(services->context,cc);
    if (!is_first_arg) {
      if (is_print) {
	if (cc->token==',')
	  (*services->lex)(services->context,cc);
	else if (cc->token!=';')
	  (*services->report)(services->context,cc,0,"Expecting ',' at ");
      } else {
	if (needs_right_paren) {
	  if (cc->token==',')
	    (*services->lex)(services->context,cc);
	  else if (cc->token!=')')
	    (*services->report)(services->context,cc,0,"Expecting ',' at ");
	}
      }
    }
    if (tmpm->flags & MLF_DFT_AVAILABLE &&
	  (cc->token==')' || cc->token==',' || !needs_right_paren)) {
      dft_val=tmpm->dft_val;
      if (tmpm->flags & MLF_LASTCLASS && last_class)
	dft_val=(last_class-last_class->ptr_stars_cnt)->str;
      if (tmpm->flags & (MLF_STR_DFT_AVAILABLE|MLF_LASTCLASS) &&
	    cc->flags&CCF_AOT_COMPILE) {
	cm=(*services->misc)(services->context,cc,CMT_STR_CONST);
	PrsEmit(services,cc,IC_STR_CONST,cm,services->types[RT_U8]+1);
	cm->st_len=StrLen(dft_val)+1;
	cm->str=(*services->duplicate)(services->context,dft_val);
	cc->flags|=CCF_HAS_MISC_DATA;
      } else
	PrsEmit(services,cc,IC_IMM_I64,dft_val,tmpm->member_class);
    } else {
      if (!(*services->expression)(services->context,cc,NULL,FALSE,ps))
	throw('Compiler');
      else {
	(*services->push)(services->context,cc);
	cc->pass=0;	 (*services->optimize)(services->context,cc);
	cc->pass=1; tmpi=(*services->optimize)(services->context,cc);
	(*services->pop)(services->context,cc);
	last_class=PrsClassFwdView(services,tmpi->ic_class);
	tmpc2=PrsClassFwdView(services,tmpm->member_class);
	if (tmpc2->raw_type==RT_F64 && !tmpm->dim.next &&
	      last_class->raw_type!=RT_F64)
	  tmpi->ic_flags|=ICF_RES_TO_F64;
	else
	  if (tmpc2->raw_type!=RT_F64 && last_class->raw_type==RT_F64)
	    tmpi->ic_flags|=ICF_RES_TO_INT;
      }
    }
    (*services->push)(services->context,cc);
    is_first_arg=FALSE;
    tmpm=tmpm->next;
  }
  if (tmpm && tmpm->flags & MLF_DOT_DOT_DOT) {
    (*services->init)(services->context,cc);
    tmpi=PrsEmit(services,cc,IC_IMM_I64,0,tmpm->member_class);
    (*services->push)(services->context,cc);
    if (is_print) {
      if (cc->token!=';') {
	do {
	  if (!is_first_arg) {
	    if (cc->token==',')
	      (*services->lex)(services->context,cc);
	    else
	      (*services->report)(services->context,cc,0,"Expecting ',' at ");
	  }
	  (*services->init)(services->context,cc);
	  if (!(*services->expression)(services->context,cc,NULL,FALSE,ps))
	    throw('Compiler');
	  (*services->push)(services->context,cc);
	  is_first_arg=FALSE;
	  argc_cnt++;
	} while (cc->token==',');
      }
    } else if (needs_right_paren) {
      if (cc->token!=')') {
	do {
	  if (!is_first_arg) {
	    if (cc->token==',')
	      (*services->lex)(services->context,cc);
	    else
	      (*services->report)(services->context,cc,0,"Expecting ',' at ");
	  }
	  (*services->init)(services->context,cc);
	  if (!(*services->expression)(services->context,cc,NULL,FALSE,ps))
	    throw('Compiler');
	  (*services->push)(services->context,cc);
	  is_first_arg=FALSE;
	  argc_cnt++;
	} while (cc->token==',');
      }
    }
    tmpi->ic_data=argc_cnt++; //++ so add_esp latter works
  }
  if (needs_right_paren) {
    if (cc->token==')')
      (*services->lex)(services->context,cc);
    else
      (*services->report)(services->context,cc,0,"Missing ')' at ");
  }
  tmpcbh1=tmpcbh->coc_next;
  tmpcbh->coc_next=cc->coc.coc_next;
  cc->coc.coc_next=tmpcbh;
  (*services->pop)(services->context,cc);
  tmpcbh=cc->coc.coc_next;
  cc->coc.coc_next=tmpcbh1;
  if (!is_template_fun)
    PrsEmit(services,cc,IC_CALL_START,tmpf,0);
  if (indirect)
    PrsEmit(services,cc,IC_PUSH_REGS,1<<REG_RAX,tmpf->return_class);
  while (tmpcbh) {
    tmpcbh1=tmpcbh->coc_next;
    (*services->append)(services->context,cc,tmpcbh);
    if (!Bt(&tmpf->flags,Ff_INTERNAL))
      cc->coc.coc_head.last->ic_flags|=ICF_PUSH_RES;
    tmpcbh=tmpcbh1;
  }
  if (Bt(&tmpf->flags,Ff_INTERNAL))
    PrsEmit(services,cc,tmpf->exe_addr,0,tmpf->return_class);
  else {
    if (indirect)
      PrsEmit(services,cc,IC_CALL_INDIRECT,
	    (argc_cnt+tmpf->arg_cnt)<<3,tmpf->return_class);
    else if (Bt(&tmpf->flags,Cf_EXTERN)) {
      cc->abs_cnts.externs++;
      if (cc->flags&CCF_AOT_COMPILE) {
	if (tmpf->type&HTF_IMPORT)
	  PrsEmit(services,cc,IC_CALL_IMPORT,tmpf,tmpf->return_class);
	else
	  PrsEmit(services,cc,IC_CALL_EXTERN,tmpf,tmpf->return_class);
      } else
	PrsEmit(services,cc,IC_CALL_INDIRECT2,&tmpf->exe_addr,tmpf->return_class);
    } else
      PrsEmit(services,cc,IC_CALL,tmpf->exe_addr,tmpf->return_class);
    if ((Bt(&tmpf->flags,Ff_RET1) || Bt(&tmpf->flags,Ff_ARGPOP)) &&
	  !Bt(&tmpf->flags,Ff_NOARGPOP)) {
      if (indirect) {
	PrsEmit(services,cc,IC_ADD_RSP1,(argc_cnt+tmpf->arg_cnt)<<3,tmpf->return_class);
	PrsEmit(services,cc,IC_ADD_RSP,8,tmpf->return_class);
      } else
	PrsEmit(services,cc,IC_ADD_RSP1,(argc_cnt+tmpf->arg_cnt)<<3,tmpf->return_class);
    } else {
      if (indirect)
	argc_cnt++;
      PrsEmit(services,cc,IC_ADD_RSP,(argc_cnt+tmpf->arg_cnt)<<3,tmpf->return_class);
    }
  }
  if (!is_template_fun)
    PrsEmit(services,cc,IC_CALL_END,tmpf,tmpf->return_class);
  if (is_print||is_putchars)
    PrsEmit(services,cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);
  cc->flags=(cc->flags|CCF_RAX) & ~(CCF_ARRAY|CCF_FUN_EXP);
  return PE_UNARY_MODIFIERS;
}

I64 PrsUnaryTermCore(CPrsExpressionServices *services,CCmpCtrl *cc,CPrsStk *ps,CMemberLst **_local_var,
	CArrayDim **_tmpad,I64 *max_prec,I64 *unary_pre_prec,I64 *paren_prec)
{
  I64 i,j;
  CHashExport *tmpex;
  CHashClass *tmpc;
  CHashFun *tmpf;
  CHashGlblVar *tmpg;
  CMemberLst *tmpm;
  CAsmUndefHash *tmpauh;
  CCodeMisc *cm;
  Bool paren_warn;

  *_local_var=NULL;
  *paren_prec=PREC_NULL;
  switch (cc->token) {
    start:
      if (PREC_UNARY_PRE>*max_prec)
	*max_prec=PREC_UNARY_PRE;
      *unary_pre_prec=PREC_UNARY_PRE;
      start:
	case '~': i=IC_COM;		break;
	case '!': i=IC_NOT;		break;
	case '-': i=IC_UNARY_MINUS;	break;
	case '*': i=IC_DEREF;		break;
      end:
	(*services->lex)(services->context,cc); //Skip op
	break;
      case '&':
	if ((*services->lex)(services->context,cc)==TK_IDENT) {
	  if (tmpc=cc->hash_entry) {
	    if (tmpc->type & HTT_FUN) {
	      tmpf=tmpc;
	      if (!Bt(&tmpf->flags,Ff_INTERNAL)) {
		if (Bt(&tmpf->flags,Cf_EXTERN)) {
		  if (cc->flags&CCF_AOT_COMPILE) {
		    if (cc->flags&CCF_ASM_EXPRESSIONS) {
		      if (tmpex=HashFind(tmpf->str,cc->htc.hash_table_lst,
			    HTT_EXPORT_SYS_SYM))
			goto pu_export_sys_sym;
		      else
			goto pu_new_sys_sym;
		    }
		    if (cc->flags&CCF_TARGET_I386)
		      PrsEmit(services,cc,IC_ADDR_IMPORT,tmpf,services->types[RT_PTR]);
		    else (*services->report)(services->context,cc,0,"Can't take addr of extern fun");
		  } else {
		    cc->abs_cnts.externs++;
		    if(services->retain_function_addresses)
		      PrsEmit(services,cc,IC_ADDR_IMPORT,tmpf,services->types[RT_PTR]);
		    else {
		      PrsEmit(services,cc,IC_IMM_I64,
			&tmpf->exe_addr,services->types[RT_PTR]);
		      PrsEmit(services,cc,IC_DEREF,0,services->types[RT_PTR]);
		    }
		  }
		} else {
		  if (cc->flags&CCF_AOT_COMPILE) {
		    PrsEmit(services,cc,IC_ABS_ADDR,
			  tmpf->exe_addr,services->types[RT_PTR]);
		    if (cc->flags&CCF_ASM_EXPRESSIONS)
		      cc->abs_cnts.abs_addres++;
		  } else if(services->retain_function_addresses)
		    PrsEmit(services,cc,IC_ADDR_IMPORT,tmpf,services->types[RT_PTR]);
		  else
		    PrsEmit(services,cc,IC_IMM_I64,
			  tmpf->exe_addr,services->types[RT_PTR]);
		}
		cc->abs_cnts.c_addres++;
		(*services->lex)(services->context,cc);
		return PE_MAYBE_MODIFIERS;
	      }
	    } else if (tmpc->type & HTT_EXPORT_SYS_SYM) {
	      tmpex=tmpc;
	      if (cc->flags&CCF_ASM_EXPRESSIONS &&
		    !(cc->flags&CCF_AOT_COMPILE) && tmpex->type&HTF_IMM) {
		cc->abs_cnts.c_addres++;
		PrsEmit(services,cc,IC_IMM_I64,
		      tmpex->val,services->types[RT_PTR]);
		(*services->lex)(services->context,cc);
		return PE_MAYBE_MODIFIERS;
	      } else
		goto pu_export_sys_sym;
	    }
	  } else if (cc->flags&CCF_ASM_EXPRESSIONS && !cc->local_var_entry)
	    goto pu_ident_but_not_local_var;
	}
	i=IC_ADDR;
	break;
    end:
      PrsPush(ps,tmpc);
      PrsPush(ps,PREC_UNARY_PRE<<16+i);
      return PE_UNARY_TERM2;

    start:
      case TK_I64:
      case TK_CHAR_CONST:
      case TK_INS_BIN_SIZE:
	if (cc->cur_i64<0)
	  PrsEmit(services,cc,IC_IMM_I64,cc->cur_i64,services->types[RT_U64]);
	else
	  PrsEmit(services,cc,IC_IMM_I64,cc->cur_i64,services->types[RT_I64]);
	(*services->lex)(services->context,cc);
	break;
      case TK_F64:
	PrsEmit(services,cc,IC_IMM_F64,cc->cur_f64(I64),services->types[RT_F64]);
	(*services->lex)(services->context,cc);
	break;
      case TK_STR:
	cm=(*services->misc)(services->context,cc,CMT_STR_CONST);
	PrsEmit(services,cc,IC_STR_CONST,cm,services->types[RT_U8]+1);
	cm->str=(*services->string)(services->context,cc,&cm->st_len);
	cc->flags|=CCF_HAS_MISC_DATA;
	break;
      case TK_INS_BIN:
	cm=(*services->misc)(services->context,cc,CMT_STR_CONST);
	PrsEmit(services,cc,IC_STR_CONST,cm,services->types[RT_U8]+1);
	cm->str=cc->cur_str;
	cm->st_len=cc->cur_str_len;
	cc->cur_str=NULL;
	cc->flags|=CCF_HAS_MISC_DATA;
	(*services->lex)(services->context,cc);
	break;
      case '$$':
	if (cc->flags & CCF_ASM_EXPRESSIONS) {
	  cc->abs_cnts.abs_addres++;
	  if (cc->flags&CCF_AOT_COMPILE)
	    PrsEmit(services,cc,IC_ABS_ADDR,cc->aotc->rip,services->types[RT_PTR]);
	  else
	    PrsEmit(services,cc,IC_IMM_I64,cc->aotc->rip,services->types[RT_PTR]);
	} else {
	  if (cc->flags&CCF_CLASS_DOL_OFFSET)
	    PrsEmit(services,cc,IC_IMM_I64,cc->class_dol_offset,
		  services->types[RT_I64]);
	  else
	    PrsEmit(services,cc,IC_RIP,0,services->types[RT_PTR]);
	}
	(*services->lex)(services->context,cc);
	break;
    end:
      if (PREC_TERM>*max_prec)
	*max_prec=PREC_TERM;
      return PE_MAYBE_MODIFIERS;

    case '(':
      if ((*services->lex)(services->context,cc)==TK_IDENT && cc->hash_entry &&
	    cc->hash_entry->type & (HTT_CLASS|HTT_INTERNAL_TYPE))
	(*services->report)(services->context,cc,0,"Use TempleOS postfix typecasting at ");
      else {
	if (PREC_TERM>*max_prec)
	  *max_prec=PREC_TERM;
	if (cc->lex_include_stk->flags&LFSF_DEFINE)
	  paren_warn=FALSE;
	else
	  paren_warn=TRUE;
	if (!(*services->expression)(services->context,cc,paren_prec,FALSE,ps))
	  throw('Compiler');
	if (!paren_warn)
	  *paren_prec=PREC_NULL;
	if (cc->token!=')')
	  (*services->report)(services->context,cc,0,"Missing ')' at ");
	(*services->lex)(services->context,cc); //skip )
	cc->flags= cc->flags & ~CCF_ARRAY | CCF_RAX | CCF_PAREN;
	return PE_UNARY_MODIFIERS;
      }

    start:
      case '+': 				  break;
      case TK_PLUS_PLUS:   cc->flags|=CCF_PREINC; break;
      case TK_MINUS_MINUS: cc->flags|=CCF_PREDEC; break;
    end:
      if (PREC_UNARY_PRE>*max_prec)
	*max_prec=PREC_UNARY_PRE;
      *unary_pre_prec=PREC_UNARY_PRE;
      (*services->lex)(services->context,cc);
      return PE_UNARY_TERM2;

    case TK_IDENT:
      if (tmpm=cc->local_var_entry) {
	if (PREC_TERM>*max_prec)
	  *max_prec=PREC_TERM;
	cc->flags&=~(CCF_RAX|CCF_ARRAY|CCF_FUN_EXP);
	tmpc=tmpm->member_class+1;
	if (tmpm->flags & MLF_FUN && !(cc->flags&CCF_ASM_EXPRESSIONS)) {
	  PrsPopDeref(ps);
	  cc->flags|=CCF_FUN_EXP;
	  PrsPush2(ps,tmpm->fun_ptr-tmpm->fun_ptr->ptr_stars_cnt);
	}
	if (tmpm->dim.next) {
	  *_tmpad=tmpm->dim.next;
	  cc->flags|=CCF_ARRAY;
	}
	if (tmpm->flags&MLF_STATIC) {
	  if (cc->flags&CCF_AOT_COMPILE) {
//	if (tmpg->flags&GVF_DATA_HEAP) //TODO
	    //	  PrsEmit(services,cc,IC_HEAP_GLBL,tmpm->static_data,tmpc);
	    //	else
	    PrsEmit(services,cc,IC_ABS_ADDR,tmpm->static_data_rip,tmpc);
	  } else
	    PrsEmit(services,cc,IC_IMM_I64,tmpm->static_data,tmpc);
	} else {
	  if (cc->flags&CCF_ASM_EXPRESSIONS) {
	    i=PrsPop(ps);
	    ps->ptr--;
	    if (i.u16[0]!=IC_ADDR)
	      (*services->report)(services->context,cc,0,"Expecting '&' at ");
	    PrsEmit(services,cc,IC_IMM_I64,tmpm->offset,services->types[RT_PTR]);
	    *_local_var=tmpm;
	    (*services->lex)(services->context,cc);
	    return PE_MAYBE_MODIFIERS;
	  } else {
	    if (tmpm->dim.next && tmpm->offset>0 &&
		  StrCmp(tmpm->str,"argv")) {
	      tmpc++;
	      cc->flags&=~CCF_ARRAY;
	    }
	    PrsEmit(services,cc,IC_RBP,0,tmpc);
	    PrsEmit(services,cc,IC_IMM_I64,tmpm->offset,tmpc);
	    PrsEmit(services,cc,IC_ADD,0,tmpc);
	  }
	}
	(*services->lex)(services->context,cc); //skip var name
	*_local_var=tmpm;
	return PE_UNARY_MODIFIERS;
      }
pu_ident_but_not_local_var:
      if (!(tmpex=cc->hash_entry)) {
	if (!(cc->flags & CCF_ASM_EXPRESSIONS))
	  (*services->report)(services->context,cc,0,"Invalid lval at ");
	tmpc=NULL;
pu_new_sys_sym:
	tmpex=(*services->allocate)(services->context,sizeof(CHashExport),TRUE,TRUE);
	tmpex->str=cc->cur_str;
	cc->cur_str=NULL;
	if (!cc->htc.local_var_lst &&
	      *tmpex->str=='@' && tmpex->str[1]=='@') {
	  tmpex->type=HTT_EXPORT_SYS_SYM | HTF_UNRESOLVED | HTF_LOCAL;
	  (*services->hash_add)(services->context,tmpex,cc->htc.local_hash_table);
	} else {
	  tmpex->type=HTT_EXPORT_SYS_SYM | HTF_UNRESOLVED;
	  if (tmpc)
	    (*services->hash_after)(services->context,tmpex,tmpc,cc->htc.glbl_hash_table);
	  else
	    (*services->hash_add)(services->context,tmpex,cc->htc.glbl_hash_table);
	}
      }
      switch (Bsf(tmpex->type)) {
	case HTt_EXPORT_SYS_SYM:
pu_export_sys_sym:
	  if (PREC_TERM>*max_prec)
	    *max_prec=PREC_TERM;
	  if (!(tmpex->type & (HTF_IMM|HTF_IMPORT)))
	    cc->abs_cnts.abs_addres++;
	  if (tmpex->type & HTF_UNRESOLVED) {
	    if (!(cc->flags&CCF_ASM_EXPRESSIONS))
	      (*services->report)(services->context,cc,0,"Illegal fwd ref at ");
	    tmpauh=(*services->allocate)(services->context,sizeof(CAsmUndefHash),FALSE,FALSE);
	    tmpauh->hash=tmpex;
	    tmpauh->next=cc->asm_undef_hash;
	    cc->asm_undef_hash=tmpauh;
	    if (tmpex->type & HTF_LOCAL)
	      cc->flags|=CCF_UNRESOLVED|CCF_LOCAL;
	    else
	      cc->flags|=CCF_UNRESOLVED;
	    PrsEmit(services,cc,IC_IMM_I64,
		  &tmpex->val,services->types[RT_PTR],ICF_NO_RIP);
	    PrsEmit(services,cc,IC_DEREF,0,services->types[RT_PTR]);
	  } else {
	    if (cc->flags&CCF_AOT_COMPILE && !(tmpex->type & HTF_IMM))
	      PrsEmit(services,cc,IC_ABS_ADDR,tmpex->val,services->types[RT_PTR]);
	    else {
	      if (tmpex->type&HTF_IMM)
		cc->abs_cnts.c_addres++;
	      PrsEmit(services,cc,IC_IMM_I64,tmpex->val,services->types[RT_PTR]);
	    }
	  }
	  (*services->lex)(services->context,cc);
	  return PE_MAYBE_MODIFIERS;
	case HTt_FUN:
	  if (PREC_TERM>*max_prec)
	    *max_prec=PREC_TERM;
	  (*services->lex)(services->context,cc);  //skip fun name
	  return PrsFunCallCore(services,cc,ps,FALSE,tmpex);
	case HTt_GLBL_VAR:
	  if (PREC_TERM>*max_prec)
	    *max_prec=PREC_TERM;
	  tmpg=tmpex;
	  tmpc=tmpg->var_class+1;
	  cc->flags&=~(CCF_RAX|CCF_ARRAY|CCF_FUN_EXP);
	  if (tmpg->flags&GVF_ARRAY) {
	    *_tmpad=tmpg->dim.next;
	    cc->flags|=CCF_ARRAY;
	  }
	  if (cc->flags&CCF_AOT_COMPILE) {
	    if (tmpg->flags & GVF_EXTERN) //TODO
	      (*services->report)(services->context,cc,0,"Feature not implemented ");
	    else {
	      if (tmpg->flags & GVF_IMPORT)
		PrsEmit(services,cc,IC_ADDR_IMPORT,tmpg,tmpc);
	      else {
		if (tmpg->flags&GVF_DATA_HEAP)
		  PrsEmit(services,cc,IC_HEAP_GLBL,tmpg->heap_glbl,tmpc);
		else
		  PrsEmit(services,cc,IC_ABS_ADDR,tmpg->data_addr_rip,tmpc);
	      }
	    }
	  } else {
	    if (tmpg->flags & GVF_EXTERN) {
	      cc->abs_cnts.externs++;
	      PrsEmit(services,cc,IC_IMM_I64,&tmpg->data_addr,tmpc);
	      PrsEmit(services,cc,IC_DEREF,0,tmpc);
	    } else if(services->retain_data_addresses && !(tmpg->flags&GVF_ALIAS))
	      PrsEmit(services,cc,IC_ADDR_IMPORT,tmpg,tmpc);
	    else
	      PrsEmit(services,cc,IC_IMM_I64,tmpg->data_addr,tmpc);
	  }
	  (*services->lex)(services->context,cc);
	  if (tmpg->flags & GVF_FUN) {
	    PrsPopDeref(ps);
	    cc->flags|=CCF_FUN_EXP;
	    PrsPush2(ps,tmpg->fun_ptr-tmpg->fun_ptr->ptr_stars_cnt);
	  }
	  return PE_UNARY_MODIFIERS;
	case HTt_CLASS:
	  PrsOffsetOfCore(services,cc);
	  return PE_MAYBE_MODIFIERS;
	case HTt_KEYWORD:
	  switch (tmpex(CHashGeneric *)->user_data0) {
	    case KW_SIZEOF:
	      if (PREC_TERM>*max_prec)
		*max_prec=PREC_TERM;
	      j=0;
	      while ((*services->lex)(services->context,cc)=='(')
		j++;
	      PrsSizeOfCore(services,cc);
	      while (j--) {
		if (cc->token!=')')
		  (*services->report)(services->context,cc,0,"Missing ')' at ");
		(*services->lex)(services->context,cc);
	      }
	      return PE_MAYBE_MODIFIERS;
	    case KW_OFFSET:
	      if (PREC_TERM>*max_prec)
		*max_prec=PREC_TERM;
	      j=0;
	      while ((*services->lex)(services->context,cc)=='(')
		j++;
	      PrsOffsetOfCore(services,cc);
	      while (j--) {
		if (cc->token!=')')
		  (*services->report)(services->context,cc,0,"Missing ')' at ");
		(*services->lex)(services->context,cc);
	      }
	      return PE_MAYBE_MODIFIERS;
	    case KW_DEFINED:
	      if (PREC_TERM>*max_prec)
		*max_prec=PREC_TERM;
	      j=0;
	      while ((*services->lex)(services->context,cc)=='(')
		j++;
	      if (cc->token==TK_IDENT &&
		    (cc->hash_entry || cc->local_var_entry))
		PrsEmit(services,cc,IC_IMM_I64,TRUE,services->types[RT_I64]);
	      else
		PrsEmit(services,cc,IC_IMM_I64,FALSE,services->types[RT_I64]);
	      (*services->lex)(services->context,cc);
	      while (j--) {
		if (cc->token!=')')
		  (*services->report)(services->context,cc,0,"Missing ')' at ");
		(*services->lex)(services->context,cc);
	      }
	      return PE_MAYBE_MODIFIERS;
	  }
      }
  }
  (*services->report)(services->context,cc,0,"Missing expression at ");
}

I64 PrsUnaryModifierCore(CPrsExpressionServices *services,CCmpCtrl *cc,CPrsStk *ps,CMemberLst **_local_var,
	CArrayDim **_tmpad,I64 *unary_post_prec)
{
  CHashClass *tmpc,*tmpc1;
  CHashFun *fun_ptr;
  CMemberLst *tmpm=*_local_var;
  CIntermediateCode *tmpi,*tmpi1;
  CArrayDim *tmpad1,tmpad2;
  CCodeMisc *cm;
  I64 mode,old_flags;
  Bool was_paren=Btr(&cc->flags,CCf_PAREN),preserve_arrow_type=FALSE;

  *_local_var=NULL;
  switch (cc->token) {
    case '.':
      if (tmpm)
	tmpm->reg=REG_NONE;
      goto um_join;

    case TK_DEREFERENCE:
      tmpi=cc->coc.coc_head.last;
      if (!(cc->flags & (CCF_RAX | CCF_ARRAY)))
	PrsEmit(services,cc,IC_DEREF+PREC_UNARY_PRE<<16,0,tmpi->ic_class-1);
      else if (cc->flags&CCF_TARGET_I386 && cc->flags&CCF_RAX)
        preserve_arrow_type=TRUE;
      else
	tmpi->ic_class--;

	um_join:
      if (!*unary_post_prec)
	*unary_post_prec=PREC_TERM;
      tmpc=cc->coc.coc_head.last->ic_class;
      //A computed pointer retains its emitted scalar type. Only member lookup
      //uses the pointee class; mutating a preceding DEREF makes i386 load a struct.
      if (preserve_arrow_type) tmpc--;
      if ((!tmpc->ptr_stars_cnt || cc->flags & CCF_ARRAY) && cc->token=='.')
	(*services->report)(services->context,cc,0,"Must be address, not value ");
      if (!(cc->flags & CCF_RAX))
	tmpc--;
      if (!(tmpc->type & HTT_CLASS))
	(*services->report)(services->context,cc,0,"Invalid class at ");
      if ((*services->lex)(services->context,cc)!=TK_IDENT ||
	    !(tmpm=MemberFind(cc->cur_str,PrsClassView(services,tmpc))))
	(*services->report)(services->context,cc,0,"Invalid member at ");
      else if (cc->local_var_entry)
	cc->local_var_entry->use_cnt--;
      (*services->lex)(services->context,cc);	//skip member name
      tmpc1=tmpm->member_class+1;
      PrsEmit(services,cc,IC_IMM_I64,tmpm->offset,tmpc1);
      cc->flags&=~(CCF_RAX|CCF_ARRAY|CCF_FUN_EXP);
      if (tmpm->dim.next) {
	*_tmpad=tmpm->dim.next;
	cc->flags|=CCF_ARRAY;
      }
      if(tmpm->flags & MLF_FUN) {
	PrsPopDeref(ps);
	PrsPush2(ps,tmpm->fun_ptr-tmpm->fun_ptr->ptr_stars_cnt);
	cc->flags|=CCF_FUN_EXP;
      }
      PrsEmit(services,cc,IC_ADD,0,tmpc1);
      return PE_UNARY_MODIFIERS;
    case '(':
      if (cc->flags & CCF_FUN_EXP) {
	if (!*unary_post_prec)
	  *unary_post_prec=PREC_TERM;
	return PrsFunCallCore(services,cc,ps,TRUE,PrsPop2(ps));
      }
      if (!*unary_post_prec)
	*unary_post_prec=PREC_TERM;
      if ((*services->lex)(services->context,cc)!=TK_IDENT)
	(*services->report)(services->context,cc,0,"Invalid class at ");
      if (Btr(&cc->flags,CCf_FUN_EXP))
	ps->ptr2--;
      cc->flags&=~CCF_ARRAY;
      tmpc=cc->hash_entry;
      (*services->lex)(services->context,cc);
      mode=PRS0_TYPECAST|PRS1_NULL;
      tmpc=(*services->type)(services->context,cc,&tmpc,&mode,NULL,NULL,&fun_ptr,NULL,&tmpad2,0);
      if (fun_ptr) {
	PrsPopDeref(ps);
	Bts(&cc->flags,CCf_FUN_EXP);
	PrsPush2(ps,fun_ptr);
	cm=(*services->misc)(services->context,cc,CMT_HASH_ENTRY);
	cm->h=fun_ptr;
      }
      if (*_tmpad=tmpad2.next) {
	cc->flags|=CCF_ARRAY;
	tmpc++;
	cm=(*services->misc)(services->context,cc,CMT_ARRAY_DIM);
	cm->dim=*_tmpad;
      }
      if (!(cc->flags&(CCF_RAX|CCF_ARRAY)))
	tmpc++;
      tmpi=cc->coc.coc_head.last;
      tmpi->ic_class=tmpc;
      PrsEmit(services,cc,IC_HOLYC_TYPECAST,was_paren,tmpc);
      if (cc->token!=')')
	(*services->report)(services->context,cc,0,"Missing ')' at ");
      (*services->lex)(services->context,cc);
      return PE_UNARY_MODIFIERS;
    case '[':
      if (!*unary_post_prec)
	*unary_post_prec=PREC_TERM;
      (*services->lex)(services->context,cc);
      tmpc=PrsClassFwdView(services,cc->coc.coc_head.last->ic_class);
      if (!tmpc->ptr_stars_cnt)
	(*services->report)(services->context,cc,0,"Not array or ptr ");
      if (!(cc->flags & (CCF_ARRAY | CCF_RAX))) {
	tmpc=PrsClassFwdView(services,tmpc-1);
	if (!tmpc->ptr_stars_cnt)
	  (*services->report)(services->context,cc,0,"Not array or ptr ");
	PrsEmit(services,cc,IC_DEREF+PREC_UNARY_PRE<<16,0,tmpc);
      }
      tmpc1=tmpc-1;
      if (tmpad1=*_tmpad) {
	PrsEmit(services,cc,IC_IMM_I64,tmpad1->total_cnt*PrsClassViewSize(services,cc,tmpc1),tmpc);
	if (*_tmpad=tmpad1->next) {
	  old_flags=cc->flags;
	  if (!(*services->expression)(services->context,cc,NULL,FALSE,ps))
	    throw('Compiler');
	  cc->flags=cc->flags&~CCF_FUN_EXP|old_flags&CCF_FUN_EXP;
	  if (cc->token!=']')
	    (*services->report)(services->context,cc,0,"Missing ']' at ");
	  (*services->lex)(services->context,cc); //skip ]
	  tmpi1=cc->coc.coc_head.last;
	  tmpi1->ic_flags|=ICF_RES_TO_INT;
	  PrsEmit(services,cc,IC_MUL,0,tmpc);
	  PrsEmit(services,cc,IC_ADD,0,tmpc);
	  cc->flags|=CCF_RAX;
	  return PE_UNARY_MODIFIERS;
	}
      } else
	PrsEmit(services,cc,IC_IMM_I64,PrsClassViewSize(services,cc,tmpc1),tmpc);
      old_flags=cc->flags;
      if (!(*services->expression)(services->context,cc,NULL,FALSE,ps))
	throw('Compiler');
      cc->flags=cc->flags&~CCF_FUN_EXP|old_flags&CCF_FUN_EXP;
      if (cc->token!=']')
	(*services->report)(services->context,cc,0,"Missing ']' at ");
      (*services->lex)(services->context,cc); //skip ]
      tmpi1=cc->coc.coc_head.last;
      tmpi1->ic_flags|=ICF_RES_TO_INT;
      PrsEmit(services,cc,IC_MUL,0,tmpc);
      PrsEmit(services,cc,IC_ADD,0,tmpc);
      cc->flags&=~(CCF_RAX|CCF_ARRAY);
      return PE_UNARY_MODIFIERS;
    start:
      case TK_PLUS_PLUS:
	cc->flags|=CCF_POSTINC;
	break;
      case TK_MINUS_MINUS:
	cc->flags|=CCF_POSTDEC;
	break;
    end:
      if (!*unary_post_prec)
	*unary_post_prec=PREC_UNARY_POST;
      (*services->lex)(services->context,cc);
      return PE_DEREFERENCE;
  }
  return PE_DEREFERENCE;
}
