//Shared class declarations and function-header joining.
#include "/Compiler/PrsSymbol.HH"
CHashClass *PrsClassCore(CPrsSymbolServices *services,CCmpCtrl *cc,I64 keyword,I64 fsp_flags,Bool is_extern)
{
  CPrsExpressionServices *expression=services->declarations->expression;
  CHashClass *tmpc,*base_class;
  if (cc->token!=TK_IDENT)
    (*expression->report)(expression->context,cc,0,"Expecting identifier at ");
  if (is_extern) {
    tmpc=(*services->class_new)(services->context);
    tmpc->str=cc->cur_str;
    cc->cur_str=NULL;
    (*expression->hash_add)(expression->context,tmpc,cc->htc.glbl_hash_table);
    LBts(&tmpc->flags,Cf_EXTERN);
    (*services->source)(services->context,cc,tmpc,0);
    (*expression->lex)(expression->context,cc);
  } else {
    if (cc->flags&CCF_AOT_COMPILE)
      tmpc=HashFind(cc->cur_str,cc->htc.glbl_hash_table,HTT_CLASS);
    else
      tmpc=(*services->single_find)(services->context,cc->cur_str,cc->htc.glbl_hash_table,HTT_CLASS);
    if (tmpc) {
      if (!Bt(&tmpc->flags,Cf_EXTERN))
	tmpc=NULL;
      else if (tmpc->use_cnt<3)
	(*services->warning)(services->context,cc,0,tmpc);
    }
    if (tmpc) {
      (*services->declarations->release)(services->declarations->context,tmpc->src_link);
      tmpc->src_link=NULL;
      (*services->declarations->release)(services->declarations->context,tmpc->idx);
      tmpc->idx=NULL;
    } else {
      tmpc=(*services->class_new)(services->context);
      tmpc->str=cc->cur_str;
      cc->cur_str=NULL;
      (*expression->hash_add)(expression->context,tmpc,cc->htc.glbl_hash_table);
    }
    LBtr(&tmpc->flags,Cf_EXTERN);
    if (fsp_flags&FSF_PUBLIC)
      tmpc->type|=HTF_PUBLIC;
    tmpc->use_cnt=0;
    if (cc->last_U16=='\n')
      (*services->source)(services->context,cc,tmpc,-1);
    else
      (*services->source)(services->context,cc,tmpc,0);
    if ((*expression->lex)(expression->context,cc)==':') {
      if ((*expression->lex)(expression->context,cc)!=TK_IDENT || !(base_class=cc->hash_entry) ||
	    !(base_class->type&HTT_CLASS))
	(*expression->report)(expression->context,cc,0,"Invalid class at ");
      if ((*expression->lex)(expression->context,cc)==',')
	(*expression->report)(expression->context,cc,0,"Only one base class allowed at this time at ");
      tmpc->base_class=base_class;
      tmpc->size+=base_class->size;
    }
    if (keyword==KW_UNION)
      PrsVarLstCore(services->declarations,cc,tmpc,PRS0_NULL|PRS1_CLASS|PRSF_UNION);
    else
      PrsVarLstCore(services->declarations,cc,tmpc,PRS0_NULL|PRS1_CLASS);
    tmpc->size+=tmpc->neg_offset;
  }
  return tmpc;
}

CHashFun *PrsFunJoinCore(CPrsSymbolServices *services,CCmpCtrl *cc,CHashClass *tmp_return,
	U8 *name,I64 fsp_flags)
{
  CPrsExpressionServices *expression=services->declarations->expression;
  CMemberLst *tmpm,*header_lst;
  CAOTCtrl *aotc=cc->aotc;
  CHashClass *header_return;
  CHashFun *tmpf;
  I64 header_arg_cnt;
  if (name) {//if not fun_ptr
    if (cc->flags&CCF_AOT_COMPILE) {
      if ((tmpf=HashFind(name,cc->htc.glbl_hash_table,HTT_FUN)) &&
	    tmpf->type & HTF_IMPORT)
	tmpf=NULL;
    } else
      if ((tmpf=(*services->single_find)(services->context,name,cc->htc.glbl_hash_table,HTT_FUN)) &&
	    !Bt(&tmpf->flags,Cf_EXTERN))
	tmpf=NULL;
    if (tmpf && tmpf->use_cnt<3)
      (*services->warning)(services->context,cc,0,tmpf);
  } else
    tmpf=NULL;
  if (tmpf) {
    tmpf->used_reg_mask=services->used_mask;
    (*services->declarations->release)(services->declarations->context,tmpf->src_link);
    tmpf->src_link=NULL;
    (*services->declarations->release)(services->declarations->context,tmpf->idx);
    tmpf->idx=NULL;
    (*services->declarations->release)(services->declarations->context,name);
    header_arg_cnt=tmpf->arg_cnt;
    header_lst=tmpf->member_lst_and_root;
    header_return=tmpf->return_class;
    tmpf->member_lst_and_root=NULL;
    (*services->class_members_delete)(services->context,tmpf);
  } else {
    tmpf=(*services->fun_new)(services->context);
    header_return=NULL;
    tmpf->used_reg_mask=services->used_mask;
    tmpf->clobbered_reg_mask=services->clobbered_mask;
    tmpf->str=name;
    if (cc->flags&CCF_AOT_COMPILE)
      tmpf->exe_addr=aotc->rip;
    else
      tmpf->exe_addr=services->undefined_function;
    LBts(&tmpf->flags,Cf_EXTERN);
    tmpf->flags|=fsp_flags&FSG_FUN_FLAGS1;
    if (name) //if not fun_ptr
      (*expression->hash_add)(expression->context,tmpf,cc->htc.glbl_hash_table);
  }
  BEqu(&tmpf->type,HTf_PUBLIC,fsp_flags&FSF_PUBLIC);
  tmpf->return_class=tmp_return;
  tmpf->use_cnt=0;
  (*services->source)(services->context,cc,tmpf,0);
  PrsVarLstCore(services->declarations,cc,tmpf,PRS0_NULL|PRS1_FUN_ARG);
  tmpf->arg_cnt=tmpf->member_cnt;
  if (0<tmpf->arg_cnt<<3<=I16_MAX && !Bt(&tmpf->flags,Ff_DOT_DOT_DOT))
    LBts(&tmpf->flags,Ff_RET1);
  tmpm=tmpf->member_lst_and_root;
  while (tmpm) {
    if (cc->flags&CCF_TARGET_I386) tmpm->offset+=8;
    else tmpm->offset+=16; //Saved frame + return
    tmpm=tmpm->next;
  }
  tmpf->size=0;
  if (header_return) {
    if ((*services->option)(services->context,OPTf_WARN_HEADER_MISMATCH)) {
      if (tmpf->return_class!=header_return) {
	(*services->warning)(services->context,cc,1,tmpf);
      }
      if (!MemberLstCmp(tmpf->member_lst_and_root,header_lst,header_arg_cnt)) {
	(*services->warning)(services->context,cc,2,tmpf);
      }
    }
    (*services->members_delete)(services->context,header_lst);
  }
  return tmpf;
}
