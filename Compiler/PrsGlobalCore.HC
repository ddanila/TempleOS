//Production global declarations, imports, aliases and function dispatch.
#include "/Compiler/PrsGlobal.HH"
U0 PrsGlblVarLstCore(CPrsGlobalServices *services,CCmpCtrl *cc,I64 saved_mode,CHashClass *saved_tmpc,
  I64 saved_val,I64 fsp_flags)
{
  CPrsSymbolServices *symbols=services->symbols;
  CPrsInitializerServices *initializers=services->initializers;
  CPrsDeclarationServices *declarations=symbols->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  I64 i,j,mode,k,val;
  U8 *st;
  CHashExport *tmpex;
  CHashGlblVar *tmpg;
  CAOTCtrl *aotc=cc->aotc;
  CAOTHeapGlbl *tmphg;
  CHashClass *tmpc;
  CHashFun *tmpf,*tmpf_fun_ptr;
  CArrayDim tmpad;
  Bool has_alias,undef_array_size,is_array;
  while (TRUE) {
    tmpc=PrsTypeCore(types,cc,&saved_tmpc,&saved_mode,NULL,&st,
	  &tmpf_fun_ptr,&tmpex,&tmpad,fsp_flags);

    if (!st) return;
    if (tmpad.next)
      is_array=TRUE;
    else if (tmpad.total_cnt<0) {
      is_array=TRUE;
      tmpc--;
    } else
      is_array=FALSE;

    val=saved_val;
    mode=saved_mode;
    if (tmpex && mode&255==PRS0_EXTERN && !(cc->flags&CCF_AOT_COMPILE) &&
	  tmpex->type&HTT_EXPORT_SYS_SYM) {
      val=tmpex->val;
      mode=PRS0__EXTERN|PRS1_NOT_REALLY__EXTERN;
    }
    if (cc->token=='(') {
      switch (mode&255) {
	case PRS0__INTERN:
	  tmpf=PrsFunJoinCore(symbols,cc,tmpc,st,fsp_flags);
	  tmpf->exe_addr=val;
	  Bts(&tmpf->flags,Ff_INTERNAL);
	  LBtr(&tmpf->flags,Cf_EXTERN);
	  return;
	case PRS0__EXTERN:
	  if (!(fsp_flags&FSF__) && !(mode&PRS1_NOT_REALLY__EXTERN))
	    (*expression->report)(expression->context,cc,0,"Expecting label with underscore at ");
	  tmpf=PrsFunJoinCore(symbols,cc,tmpc,st,fsp_flags);
	  tmpf->exe_addr=val;
	  (*services->resolve)(services->context,cc,tmpf->str);
	  LBtr(&tmpf->flags,Cf_EXTERN);
	  if (saved_mode&255==PRS0__EXTERN)
	    LBts(&tmpf->flags,Ff__EXTERN);
	  if (cc->flags&CCF_AOT_COMPILE)
	    tmpf->type|=HTF_RESOLVE;
	  return;
	case PRS0_EXTERN:
	  PrsFunJoinCore(symbols,cc,tmpc,st,fsp_flags);
	  return;
	case PRS0__IMPORT:
	  if (!(fsp_flags&FSF__))
	    (*expression->report)(expression->context,cc,0,"Expecting label with underscore at ");
	case PRS0_IMPORT:
	  if (!(cc->flags&CCF_AOT_COMPILE))
	    (*expression->report)(expression->context,cc,0,"import not needed at ");
	  else {
	    tmpf=PrsFunJoinCore(symbols,cc,tmpc,st,fsp_flags);
	    tmpf->type|=HTF_IMPORT;
	    if (mode&255==PRS0__IMPORT)
	      tmpf->import_name=(*expression->duplicate)(expression->context,val);
	    else
	      tmpf->import_name=(*expression->duplicate)(expression->context,tmpf->str);
	  }
	  return;
	default:
	  (*services->function)(services->context,cc,tmpc,st,fsp_flags);
	  return;
      }
    } else {
      if (tmpad.total_cnt<0) {
	i=0;
	undef_array_size=TRUE;
      } else {
	i=tmpad.total_cnt;
	undef_array_size=FALSE;
      }
      j=CmpTargetSize(cc,tmpc);
      j*=i;
      has_alias=FALSE;
      tmphg=NULL;
      switch (mode&255) {
	case PRS0__EXTERN:
	  if (cc->flags&CCF_AOT_COMPILE) {
	    tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,FALSE);
	    tmpg->data_addr_rip=val;
	    tmpg->type=HTT_GLBL_VAR | HTF_EXPORT;
	  } else {
	    tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,TRUE);
	    tmpg->data_addr=val;
	    tmpg->type=HTT_GLBL_VAR;
	  }
	  tmpg->flags|=GVF_ALIAS;
	  break;
	case PRS0__IMPORT:
	case PRS0_IMPORT:
	  if (!(cc->flags&CCF_AOT_COMPILE))
	    (*expression->report)(expression->context,cc,0,"import not needed at ");
	  else {
	    tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,FALSE);
	    tmpg->type=HTT_GLBL_VAR | HTF_IMPORT;
	    if (mode&255==PRS0__IMPORT)
	      tmpg->import_name=(*expression->duplicate)(expression->context,val);
	    else
	      tmpg->import_name=(*expression->duplicate)(expression->context,st);
	  }
	  break;
	case PRS0_EXTERN:
	  if (cc->flags&CCF_AOT_COMPILE) {
	    tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,FALSE);
	    tmpg->type=HTT_GLBL_VAR;
	  } else {
	    tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,TRUE);
	    tmpg->type=HTT_GLBL_VAR|HTF_UNRESOLVED;
	  }
	  break;
	default:
	  if (cc->flags&CCF_AOT_COMPILE) {
	    if (Bt(&cc->opts,OPTf_GLBLS_ON_DATA_HEAP)) {
	      if (cc->token=='=')
		(*expression->report)(expression->context,cc,0,"Can't init glbl var on data heap in AOT module ");
	      tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,FALSE);
	      tmphg=tmpg->heap_glbl=(*expression->allocate)(expression->context,sizeof(CAOTHeapGlbl),TRUE,FALSE);
	      tmphg->size=j;
	      tmphg->str=(*expression->duplicate)(expression->context,st);
	      tmphg->next=aotc->heap_glbls;
	      aotc->heap_glbls=tmphg;
	      tmpg->flags=GVF_DATA_HEAP;
	      tmpg->type=HTT_GLBL_VAR; //TODO: HTF_EXPORT
	      if (tmpex && tmpex->type & HTT_GLBL_VAR) //TODO!! extern
		(*expression->report)(expression->context,cc,0,"Feature not implemented ");
	    } else {
	      tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,FALSE);
	      if (cc->token=='=')
		tmpg->data_addr=(*expression->allocate)(expression->context,j,TRUE,FALSE);
	      if (CmpTargetSize(cc,tmpc)>=8) //align
		while (aotc->rip&7)
		  (*initializers->store_u8)(initializers->context,cc,0);
	      else if (CmpTargetSize(cc,tmpc)==4)
		while (aotc->rip&3)
		  (*initializers->store_u8)(initializers->context,cc,0);
	      else if (CmpTargetSize(cc,tmpc)==2)
		while (aotc->rip&1)
		  (*initializers->store_u8)(initializers->context,cc,0);
	      tmpg->data_addr_rip=aotc->rip;
	      tmpg->type=HTT_GLBL_VAR | HTF_EXPORT;
	      if (tmpex && tmpex->type & HTT_GLBL_VAR)
		has_alias=TRUE;
	      for (k=0;k<j;k++)
		(*initializers->store_u8)(initializers->context,cc,0); //Init AOT glbl to zero.
	    }
	  } else {
	    if (Bt(&cc->opts,OPTf_GLBLS_ON_DATA_HEAP)) {
	      tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,TRUE);
	      tmpg->data_addr=(*expression->allocate)(expression->context,j,FALSE,FALSE);
	      tmpg->flags=GVF_DATA_HEAP;
	    } else {
	      tmpg=(*expression->allocate)(expression->context,sizeof(CHashGlblVar),TRUE,TRUE);
	      tmpg->data_addr=(*expression->allocate)(expression->context,j,FALSE,TRUE);
	    }
	    tmpg->type=HTT_GLBL_VAR;
	    if (tmpex && tmpex->type&HTT_GLBL_VAR &&
		  tmpex->type&HTF_UNRESOLVED &&
		  (*services->same_heap)(services->context,tmpex,tmpg))
	      has_alias=TRUE;
	    (*declarations->initialize_static)(declarations->context,tmpg->data_addr,j);
	  }
      }
      tmpg->dim.next=tmpad.next;
      if (fsp_flags&FSF_PUBLIC)
	tmpg->type|=HTF_PUBLIC;
      tmpg->var_class=tmpc;
      tmpg->str=st;
      tmpg->size=j;
      tmpg->dim.total_cnt=i;
      tmpg->use_cnt=0;
      if (cc->last_U16=='\n')
	(*symbols->source)(symbols->context,cc,tmpg,-1);
      else
	(*symbols->source)(symbols->context,cc,tmpg,0);
      if (mode&255==PRS0_IMPORT || mode&255==PRS0__IMPORT)
	tmpg->flags|=GVF_IMPORT;
      if (mode&255==PRS0_EXTERN)
	tmpg->flags|=GVF_EXTERN;
      if (tmpf_fun_ptr) {
	tmpg->fun_ptr=tmpf_fun_ptr;
	tmpg->flags|=GVF_FUN;
      }
      if (is_array)
	tmpg->flags|=GVF_ARRAY;
      (*expression->hash_add)(expression->context,tmpg,cc->htc.glbl_hash_table);
      if (!(cc->flags&CCF_AOT_COMPILE) && !(tmpg->flags&GVF_EXTERN))
	(*services->resolve)(services->context,cc,tmpg->str);
      if (cc->token=='=') {
	if (undef_array_size) {
	  (*types->snapshot_push)(types->context,cc);
	  (*types->snapshot_push)(types->context,cc);
	  (*expression->lex)(expression->context,cc);
	  PrsGlblInitCore(initializers,cc,tmpg,1);
	  (*types->snapshot_drop)(types->context,cc);
	  tmpg->size=tmpg->dim.total_cnt*CmpTargetSize(cc,tmpc);
	  if (tmphg)
	    tmphg->size=tmpg->size;
	  if (cc->flags&CCF_AOT_COMPILE)
	    for (k=0;k<tmpg->size;k++)
	      (*initializers->store_u8)(initializers->context,cc,0);
	  else
	    (*declarations->initialize_static)(declarations->context,tmpg->data_addr,tmpg->size);
	  (*declarations->snapshot_restore)(declarations->context,cc);
	}
	(*types->snapshot_push)(types->context,cc);
	(*expression->lex)(expression->context,cc);
	PrsGlblInitCore(initializers,cc,tmpg,2);
	if (cc->flags&CCF_AOT_COMPILE)
	  for (k=0;k<tmpg->size;k++)
	    (*declarations->store_u8_at)(declarations->context,cc,tmpg->data_addr_rip+k,tmpg->data_addr[k]);
	(*types->snapshot_drop)(types->context,cc);
      }
      if (!(tmpg->flags&(GVF_EXTERN|GVF_IMPORT|GVF_ALIAS|GVF_DATA_HEAP)))
        (*declarations->data_range)(declarations->context,cc,tmpg->data_addr_rip,tmpg->size);
      if (has_alias) {
	if (tmpex(CHashGlblVar *)->use_cnt<2) {
	  (*services->alias_warning)(services->context,cc,tmpex);
	}
	tmpex(CHashGlblVar *)->flags|=GVF_ALIAS;
	tmpex(CHashGlblVar *)->data_addr=tmpg->data_addr;
	tmpex(CHashGlblVar *)->data_addr_rip=tmpg->data_addr_rip;
      }
      if (cc->token==',')
	(*expression->lex)(expression->context,cc);
      else {
	if (cc->token!=';')
	  (*expression->report)(expression->context,cc,0,"Missing ';' at");
	(*expression->lex)(expression->context,cc);
	return;
      }
    }
  }
}
