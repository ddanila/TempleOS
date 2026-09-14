//Production member/local/argument declaration loop with explicit effects.
#include "/Compiler/PrsDeclaration.HH"
U0 PrsVarLstCore(CPrsDeclarationServices *services,CCmpCtrl *cc,CHashClass *tmpc,I64 mode,I64 union_base=0)
{
  CPrsExpressionServices *expression=services->expression;
  CPrsTypeServices *types=services->types;
  I64 i,k,old_flags=cc->flags,old_flags2,type,_reg;
  CHashClass *tmpc1,*tmpc2;
  CHash *tmph;
  CMemberLst *tmpm;
  CMemberLstMeta *tmp_meta;
  U8 *machine_code;
  Bool undef_array_size,first;
  cc->flags|=CCF_DONT_MAKE_RES;
  if (mode.u8[1]==PRS1B_CLASS)
    cc->flags|=CCF_CLASS_DOL_OFFSET;
  if ((mode.u8[1]!=PRS1B_LOCAL_VAR && mode.u8[1]!=PRS1B_STATIC_LOCAL_VAR ||
	mode&PRSF_UNION) && (cc->token=='(' || cc->token=='{'))
    (*expression->lex)(expression->context,cc);
  while (TRUE) {
    if (mode&PRSF_UNION)
      cc->class_dol_offset=union_base;
    else
      cc->class_dol_offset=tmpc->size;
    while (cc->token==';')
      (*expression->lex)(expression->context,cc);
    while (cc->token=='$$') {
      if ((*expression->lex)(expression->context,cc)!='=') //skip $$
	(*expression->report)(expression->context,cc,0,"Expecting '=' at ");
      (*expression->lex)(expression->context,cc); //skip =
      cc->class_dol_offset=(*services->evaluate)(services->context,cc);
      if (-cc->class_dol_offset>tmpc->neg_offset)
	tmpc->neg_offset=-cc->class_dol_offset;
      if (mode&PRSF_UNION)
	union_base=cc->class_dol_offset;
      else
	tmpc->size=cc->class_dol_offset;
      if (cc->token!=';')
	(*expression->report)(expression->context,cc,0,"Missing ';' at");
      (*expression->lex)(expression->context,cc); //skip ;
    }
    if (cc->token==')' || cc->token=='}') {
      (*expression->lex)(expression->context,cc);
      goto pvl_done;
    }
    _reg=REG_UNDEF;
pvl_restart1:
    switch (PrsKeyWord(cc)) {
      case KW_REG:
	_reg=REG_ALLOC;
	if ((*expression->lex)(expression->context,cc)==TK_IDENT) {
	  k=(*services->define_match)(services->context,cc->cur_str,"ST_U64_REGS");
	  if (k>=0) {
	    _reg=k;
	    (*expression->lex)(expression->context,cc);
	  }
	}
	goto pvl_restart1;
      case KW_NOREG:
	_reg=REG_NONE;
	(*expression->lex)(expression->context,cc);
	goto pvl_restart1;
    }

    if (cc->token==TK_ELLIPSIS && mode.u8[1]==PRS1B_FUN_ARG) {
      PrsDotDotDotCore(types,cc,tmpc,_reg);
      goto pvl_done;
    }
    if (cc->token==TK_IDENT)
      tmph=cc->hash_entry;
    else
      tmph=NULL;
    if (!tmph)
      (*expression->report)(expression->context,cc,0,"Expecting type at ");
    k=PrsKeyWord(cc);
    if (k==KW_UNION) {
      (*expression->lex)(expression->context,cc);
      PrsVarLstCore(services,cc,tmpc,mode|PRSF_UNION,tmpc->size);
    } else {
      if (!(tmph->type & (HTT_CLASS|HTT_INTERNAL_TYPE)))
	(*expression->report)(expression->context,cc,0,"Expecting type at ");
      first=TRUE;
pvl_restart2:
      tmpc1=tmph;
      (*types->snapshot_push)(types->context,cc);
      (*expression->lex)(expression->context,cc); //skip type or ','
      tmpm=(*types->member_new)(types->context,_reg);
      _reg=REG_UNDEF;
      if (mode.u8[1]==PRS1B_STATIC_LOCAL_VAR) {
	tmpm->flags|=MLF_STATIC;
	tmpm->reg=REG_NONE;
      }
      if (mode.u8[1]==PRS1B_FUN_ARG || mode.u8[1]==PRS1B_LOCAL_VAR) {
pvl_restart3:
	switch (PrsKeyWord(cc)) {
	  case KW_REG:
	    tmpm->reg=REG_ALLOC;
	    (*types->snapshot_drop)(types->context,cc);
	    (*types->snapshot_push)(types->context,cc);
	    if ((*expression->lex)(expression->context,cc)==TK_IDENT) {
	      k=(*services->define_match)(services->context,cc->cur_str,"ST_U64_REGS");
	      if (k>=0) {
		tmpm->reg=k;
		(*types->snapshot_drop)(types->context,cc);
		(*types->snapshot_push)(types->context,cc);
		(*expression->lex)(expression->context,cc);
	      }
	    }
	    goto pvl_restart3;
	  case KW_NOREG:
	    tmpm->reg=REG_NONE;
	    (*types->snapshot_drop)(types->context,cc);
	    (*types->snapshot_push)(types->context,cc);
	    (*expression->lex)(expression->context,cc);
	    goto pvl_restart3;
	}
      }
      tmpm->member_class=PrsTypeCore(types,cc,&tmpc1,&mode,tmpm,&tmpm->str,
	    &tmpm->fun_ptr,NULL,&tmpm->dim,0);
      if (tmpm->fun_ptr)
	tmpm->flags|=MLF_FUN;
      if (first)
	(*types->member_add)(types->context,cc,tmpm,tmpc,mode.u8[1]);
      else
	(*types->member_add)(types->context,cc,tmpm,tmpc,PRS1B_NULL);
      tmpc->member_cnt++;

      tmpc2=tmpm->member_class;
      i=CmpTargetSize(cc,tmpc2)*tmpm->dim.total_cnt;
      switch (mode.u8[1]) {
	case PRS1B_STATIC_LOCAL_VAR:
	  if (i<0) {
	    i=0;
	    undef_array_size=TRUE;
	  } else
	    undef_array_size=FALSE;
	  if (mode&PRSF_UNION)
	    (*expression->report)(expression->context,cc,0,"Static unions are not implemented ");
	  k=(i+7)&~7;
	  if (cc->flags&CCF_AOT_COMPILE)
	    tmpm->static_data=(*expression->allocate)(expression->context,k,FALSE,FALSE);
	  else
	    tmpm->static_data=(*expression->allocate)(expression->context,k,FALSE,TRUE);
	  if (cc->flags&CCF_AOT_COMPILE)	{
	    tmpm->static_data_rip=cc->aotc->rip;
	    k>>=3;
	    while (k--)
	      (*services->store_u64)(services->context,cc,0);
	  } else
	    (*services->initialize_static)(services->context,tmpm->static_data,k);
	  (*types->snapshot_drop)(types->context,cc);
	  if (cc->token=='=') {
	    cc->flags=cc->flags&
		  ~CCF_DONT_MAKE_RES|old_flags&CCF_DONT_MAKE_RES;
	    if (undef_array_size) {
	      (*types->snapshot_push)(types->context,cc);
	      (*types->snapshot_push)(types->context,cc);
	      (*expression->lex)(expression->context,cc); //skip =
	      (*services->static_init)(services->context,cc,tmpm,1);
	      (*types->snapshot_drop)(types->context,cc);
	      i=CmpTargetSize(cc,tmpc2)*tmpm->dim.total_cnt;
	      k=(i+7)&~7;
	      if (cc->flags&CCF_AOT_COMPILE)	{
		k>>=3;
		while (k--)
		  (*services->store_u64)(services->context,cc,0);
	      } else
		(*services->initialize_static)(services->context,tmpm->static_data,k);
	      (*services->snapshot_restore)(services->context,cc);
	    }
	    (*types->snapshot_push)(types->context,cc);
	    (*expression->lex)(expression->context,cc); //skip =
	    (*services->static_init)(services->context,cc,tmpm,2);
	    (*types->snapshot_drop)(types->context,cc);
	    if (cc->flags&CCF_AOT_COMPILE)
	      for (k=0;k<i;k++)
		(*services->store_u8_at)(services->context,cc,tmpm->static_data_rip+k,
		      tmpm->static_data[k]);
	    tmpm->use_cnt=0;
	    cc->flags|=CCF_DONT_MAKE_RES;
	  }
          (*services->data_range)(services->context,cc,tmpm->static_data_rip,(i+7)&~7);
	  if (cc->flags&CCF_AOT_COMPILE)
	    (*services->release)(services->context,tmpm->static_data);
	  break;
	case PRS1B_LOCAL_VAR:
	  if (mode&PRSF_UNION) {
	    if (union_base-tmpc->size<i)
	      i=union_base-i-tmpc->size;
	    else
	      i=0;
	  }
	  if (i>=8)
	    tmpc->size=(tmpc->size-i)&~7;
	  else if (i>=4)
	    tmpc->size=(tmpc->size-i)&~3;
	  else if (i>=2)
	    tmpc->size=(tmpc->size-i)&~1;
	  else
	    tmpc->size-=i;
	  tmpm->offset=tmpc->size;
	  tmpm->size=i;
	  if (cc->token=='=') {
	    cc->flags=cc->flags&~CCF_DONT_MAKE_RES|
		  old_flags&CCF_DONT_MAKE_RES;
	    (*services->snapshot_restore)(services->context,cc);
	    (*expression->lex)(expression->context,cc);
	    if (!(*expression->expression)(expression->context,cc,NULL,TRUE,NULL))
	      throw('Compiler');
	    tmpm->use_cnt=0;
	    cc->flags|=CCF_DONT_MAKE_RES;
	  } else
	    (*types->snapshot_drop)(types->context,cc);
	  break;
	case PRS1B_FUN_ARG:
	  if (mode&PRSF_UNION) {
	    tmpm->offset=union_base;
	    if (tmpc->size-union_base<8)
	      tmpc->size=8+union_base;
	  } else {
	    tmpm->offset=tmpc->size;
	    tmpc->size+=8;
	  }
	  tmpm->size=8;
	  if (cc->token=='=') {
	    (*expression->lex)(expression->context,cc);
	    if (PrsKeyWord(cc)==KW_LASTCLASS) {
	      tmpm->flags|=MLF_LASTCLASS;
	      (*expression->lex)(expression->context,cc);
	    } else {
	      old_flags2=cc->flags;
	      cc->flags&=~CCF_HAS_MISC_DATA;
	      machine_code=(*services->compile_expression)(services->context,cc,&type);
	      if (!machine_code)
		throw('Compiler');
	      tmpm->dft_val=(*services->execute)(services->context,machine_code);
	      tmpc2=OptClassFwd(tmpc2);
	      if (tmpc2->raw_type==RT_F64) {
		if (type!=RT_F64)
		  tmpm->dft_val(F64)=tmpm->dft_val;
	      } else {
		if (type==RT_F64)
		  tmpm->dft_val=tmpm->dft_val(F64);
	      }
	      if (cc->flags & CCF_HAS_MISC_DATA) {
		tmpm->dft_val=(*expression->duplicate)(expression->context,tmpm->dft_val);
		tmpm->flags|=MLF_STR_DFT_AVAILABLE;
	      }
	      (*services->release)(services->context,machine_code);
	      cc->flags|=old_flags2&CCF_HAS_MISC_DATA;
	    }
	    tmpm->flags|=MLF_DFT_AVAILABLE;
	  }
	  (*types->snapshot_drop)(types->context,cc);
	  break;
	case PRS1B_CLASS:
	  if (mode&PRSF_UNION) {
	    tmpm->offset=union_base;
	    if (tmpc->size-union_base<i)
	      tmpc->size=i+union_base;
	  } else {
	    tmpm->offset=tmpc->size;
	    tmpc->size+=i;
	  }
	  tmpm->size=i;
	  if (mode&PRSF_UNION)
	    cc->class_dol_offset=union_base;
	  else
	    cc->class_dol_offset=tmpc->size;

	  while (cc->token==TK_IDENT) {
	    tmp_meta=(*expression->allocate)(expression->context,sizeof(CMemberLstMeta),FALSE,FALSE);
	    tmp_meta->next=tmpm->meta;
	    tmpm->meta=tmp_meta;
	    tmp_meta->str=cc->cur_str;
	    tmp_meta->flags=0;
	    cc->cur_str=NULL;
	    if ((*expression->lex)(expression->context,cc)==TK_STR) {
	      tmp_meta->user_data=(*expression->string)(expression->context,cc,NULL);
	      tmp_meta->flags|=MLMF_IS_STR;
	    } else
	      tmp_meta->user_data=(*services->evaluate)(services->context,cc);
	  }
	  (*types->snapshot_drop)(types->context,cc);
	  break;
      }
      switch (cc->token) {
	case ',':
	  if (mode.u8[1]==PRS1B_FUN_ARG && !(mode&PRSF_UNION))
	    (*expression->lex)(expression->context,cc);
	  else {
	    first=FALSE;
	    goto pvl_restart2;
	  }
	  break;
	case ')':
	case '}':
	  (*expression->lex)(expression->context,cc);
	  goto pvl_done;
	case ';':
	  cc->flags=cc->flags&~CCF_DONT_MAKE_RES|
		old_flags&CCF_DONT_MAKE_RES;
	  (*expression->lex)(expression->context,cc);
	  cc->flags|=CCF_DONT_MAKE_RES;
	  if ((mode.u8[1]==PRS1B_LOCAL_VAR||mode.u8[1]==
		PRS1B_STATIC_LOCAL_VAR) && !(mode&PRSF_UNION))
	    goto pvl_done;
	  break;
	default:
	  (*expression->report)(expression->context,cc,0,"Missing ';' at");
      }
    }
  }
pvl_done:
  cc->flags=cc->flags&~(CCF_CLASS_DOL_OFFSET|CCF_DONT_MAKE_RES)|
	old_flags&(CCF_CLASS_DOL_OFFSET|CCF_DONT_MAKE_RES);
}
