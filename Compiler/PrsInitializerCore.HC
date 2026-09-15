//Shared scalar, aggregate, array, global and static initialization.
#include "/Compiler/PrsInitializer.HH"
U0 PrsVarInitCore(CPrsInitializerServices *services,CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,CArrayDim *tmpad,
	U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass)
{
  CPrsDeclarationServices *declarations=services->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  U8 *dst=*_dst,*machine_code;
  I64 i,j,r,old_flags=cc->flags,type,size;
  CMemberLst *tmpm;
  CIntermediateCode *tmpi;
  CAOTCtrl *aotc=cc->aotc;
  CAOTAbsAddr *tmpa;
  CAOTImportExport *tmpie;
  Bool is_str;

  tmpc=OptClassFwd(tmpc);
  if (tmpm=tmpc->member_lst_and_root) {
    if (cc->token!='{')
      (*expression->report)(expression->context,cc,0,"Expecting '{' at ");
    (*types->snapshot_drop)(types->context,cc);
    (*types->snapshot_push)(types->context,cc);
    (*expression->lex)(expression->context,cc);
    while (tmpm) {
      PrsVarInit2Core(services,cc,&dst,tmpm->member_class,&tmpm->dim,
	    data_addr_rip,_base,data_heap,pass);
      if (cc->token==',')
	(*expression->lex)(expression->context,cc);
      tmpm=tmpm->next;
    }
    (*types->snapshot_drop)(types->context,cc);
    if (cc->token!='}')
      (*expression->report)(expression->context,cc,0,"Missing '}' at ");
    (*expression->lex)(expression->context,cc);
  } else {
    if (tmpc->ptr_stars_cnt==1 &&
	  ((tmpc-1)->raw_type==RT_I8 || (tmpc-1)->raw_type==RT_U8) &&
	  !tmpad && cc->token==TK_STR)
      is_str=TRUE;
    else
      is_str=FALSE;
    //Native JIT retains literal storage through the existing misc-data owner.
    //Stored pointers in i386 AOT modules still require target-address relocation.
    if (cc->flags&CCF_TARGET_I386 && cc->flags&CCF_AOT_COMPILE && is_str) throw('Compiler');
    if (cc->flags&CCF_AOT_COMPILE && is_str) {
      (*types->snapshot_drop)(types->context,cc);
      machine_code=(*expression->string)(expression->context,cc,&i);
      if (pass==2) {
	tmpa=(*expression->allocate)(expression->context,sizeof(CAOTAbsAddr),TRUE,FALSE);
	tmpa->next=aotc->abss;
	tmpa->type=AAT_ADD_U64;
	aotc->abss=tmpa;
	tmpa->rip=data_addr_rip+dst-*_base;
	*dst(I64 *)=aotc->rip;
	for (j=0;j<i;j++)
	  (*services->store_u8)(services->context,cc,machine_code[j]);
      }
      (*declarations->release)(declarations->context,machine_code);
    } else {
      cc->flags=CCF_NO_ABSS | cc->flags &
	    ~(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA|CCF_NOT_CONST);
      machine_code=(*declarations->compile_expression)(declarations->context,cc,&type);
      if (old_flags&CCF_AOT_COMPILE &&
	    cc->flags&CCF_NOT_CONST &&
	    !Bt(&cc->opts,OPTf_GLBLS_ON_DATA_HEAP)) {
	cc->flags=cc->flags&~CCF_NO_ABSS|CCF_AOT_COMPILE;
	(*declarations->release)(declarations->context,machine_code);
	if (pass==2) {
	  (*services->set)(services->context,dst,0,CmpTargetSize(cc,tmpc));
	  (*declarations->snapshot_restore)(declarations->context,cc);
	  (*expression->lex)(expression->context,cc);
	  (*expression->push)(expression->context,cc);
	  (*expression->init)(expression->context,cc);
	  PrsEmit(expression,cc,IC_ABS_ADDR,data_addr_rip,tmpc+1);
	  PrsEmit(expression,cc,IC_IMM_I64,dst-*_base,tmpc+1);
	  PrsEmit(expression,cc,IC_ADD,0,tmpc+1);
	  if (!(*expression->expression)(expression->context,cc,NULL,TRUE,NULL))
	    throw('Compiler');
	  tmpi=cc->coc.coc_head.last;
	  if (tmpi->ic_code==IC_END_EXP) {
	    tmpi->ic_code=IC_NOP1;
	    tmpi->ic_flags=0;
	  }
	  PrsEmit(expression,cc,IC_ASSIGN,0,tmpc);
	  PrsEmit(expression,cc,IC_END_EXP,0,tmpc,ICF_RES_NOT_USED);
	  PrsEmit(expression,cc,IC_RET,0,0);
	  if (machine_code=(*services->compile_code)(services->context,cc,&size)) {
	    tmpie=(*expression->allocate)(expression->context,sizeof(CAOTImportExport),TRUE,FALSE);
	    tmpie->type=IET_MAIN;
	    tmpie->rip=cc->aotc->rip;
	    tmpie->next=&cc->aot->next_ie; tmpie->last=cc->aot->last_ie;
	    cc->aot->last_ie->next=tmpie; cc->aot->last_ie=tmpie;
	    for (i=0;i<size;i++)
	      (*services->store_u8)(services->context,cc,machine_code[i]);
	    (*declarations->release)(declarations->context,machine_code);
	  }
	  (*expression->pop)(expression->context,cc);
	} else
	  (*types->snapshot_drop)(types->context,cc);
      } else {
	(*types->snapshot_drop)(types->context,cc);
	if (!machine_code)
	  throw('Compiler');
	r=(*declarations->execute)(declarations->context,machine_code);
	if (!(cc->flags & CCF_HAS_MISC_DATA)||pass==1)
	  (*declarations->release)(declarations->context,machine_code);

	if (type==RT_F64 &&
	      tmpc->raw_type!=RT_F64)
	  r=r(F64);
	else if (type!=RT_F64 &&
	      tmpc->raw_type==RT_F64)
	  r(F64)=r;
	(*services->copy)(services->context,dst,&r,CmpTargetSize(cc,tmpc));
      }
    }
    dst+=CmpTargetSize(cc,tmpc);
    cc->flags=cc->flags&
	  ~CCF_NO_ABSS|old_flags&(CCF_HAS_MISC_DATA|CCF_AOT_COMPILE);
  }
  *_dst=dst;
}

class CVI2
{
  CVI2 *next,*last;
  U0 base;
};

U0 PrsVarInit2Core(CPrsInitializerServices *services,CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,
	CArrayDim *tmpad,U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass)
{
  CPrsDeclarationServices *declarations=services->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  I64 i,j,cnt;
  U8 *st,*_b;
  CVI2 head,*tmpvi,*tmpvi1;
  CArrayDim *tmpad1;
  tmpc=OptClassFwd(tmpc);
  if (tmpad1=tmpad->next) {
    if (!tmpc->ptr_stars_cnt &&
	  (tmpc->raw_type==RT_I8 || tmpc->raw_type==RT_U8) &&
	  cc->token==TK_STR) {
      (*types->snapshot_drop)(types->context,cc);
      st=(*expression->string)(expression->context,cc,&i);
      if (tmpad1->cnt<0) {//[]
	tmpad1->cnt=i;
	tmpad->total_cnt=i*tmpad1->total_cnt;
	(*declarations->release)(declarations->context,*_base);
	if (data_heap)
	  *_base=(*expression->allocate)(expression->context,i,FALSE,FALSE);
	else
	  *_base=(*expression->allocate)(expression->context,i,FALSE,TRUE);
	(*services->copy)(services->context,*_base,st,i);
	*_dst=*_base+i;
      } else {
	(*services->copy)(services->context,*_dst,st,tmpad1->cnt);
	*_dst+=tmpad1->cnt;
      }
      (*declarations->release)(declarations->context,st);
      (*types->snapshot_push)(types->context,cc);
    } else {
      if (cc->token=='{') {
	(*types->snapshot_drop)(types->context,cc);
	(*types->snapshot_push)(types->context,cc);
	(*expression->lex)(expression->context,cc);
      }
      if (tmpad1->cnt<0) {//[]
	head.next=head.last=&head;
	cnt=0;
	while (cc->token!='}') {
	  tmpvi=(*expression->allocate)(expression->context,offset(CVI2.base)+tmpad1->total_cnt*CmpTargetSize(cc,tmpc),FALSE,FALSE);
	  _b=&tmpvi->base;
	  PrsVarInit2Core(services,cc,&_b,tmpc,tmpad1,data_addr_rip,_base,data_heap,pass);
	  tmpvi->next=&head; tmpvi->last=head.last;
	  head.last->next=tmpvi; head.last=tmpvi;
	  if (cc->token==',')
	    (*expression->lex)(expression->context,cc);
	  cnt++;
	}
	(*expression->lex)(expression->context,cc); //skip '}'
	tmpad1->cnt=cnt;
	tmpad->total_cnt=cnt*tmpad1->total_cnt;
	j=tmpad1->total_cnt*CmpTargetSize(cc,tmpc);
	i=cnt*j;
	(*declarations->release)(declarations->context,*_base);
	if (data_heap)
	  *_base=_b=(*expression->allocate)(expression->context,i,FALSE,FALSE);
	else
	  *_base=_b=(*expression->allocate)(expression->context,i,FALSE,TRUE);
	tmpvi=head.next;
	while (tmpvi!=&head) {
	  tmpvi1=tmpvi->next;
	  (*services->copy)(services->context,_b,&tmpvi->base,j);
	  _b+=j;
	  (*declarations->release)(declarations->context,tmpvi);
	  tmpvi=tmpvi1;
	}
	*_dst=_b;
      } else {
	for (i=0;i<tmpad1->cnt;i++) {
	  PrsVarInit2Core(services,cc,_dst,tmpc,tmpad1,data_addr_rip,_base,data_heap,pass);
	  if (tmpad1->cnt>1 && cc->token==',')
	    (*expression->lex)(expression->context,cc);
	}
	if (cc->token=='}')
	  (*expression->lex)(expression->context,cc);
      }
    }
  } else {
    PrsVarInitCore(services,cc,_dst,tmpc,tmpad1,data_addr_rip,_base,data_heap,pass);
    (*types->snapshot_push)(types->context,cc);
  }
}

U0 PrsGlblInitCore(CPrsInitializerServices *services,CCmpCtrl *cc,CHashGlblVar *tmpg,I64 pass)
{
  CPrsDeclarationServices *declarations=services->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  U8 *dst=tmpg->data_addr;
  PrsVarInit2Core(services,cc,&dst,tmpg->var_class,&tmpg->dim,
	tmpg->data_addr_rip,&tmpg->data_addr,
	Bt(&cc->opts,OPTf_GLBLS_ON_DATA_HEAP)||
	Bt(&cc->flags,CCf_AOT_COMPILE),pass);
}

U0 PrsStaticInitCore(CPrsInitializerServices *services,CCmpCtrl *cc,CMemberLst *tmpm,I64 pass)
{
  CPrsDeclarationServices *declarations=services->declarations;
  CPrsExpressionServices *expression=declarations->expression;
  CPrsTypeServices *types=declarations->types;
  U8 *machine_code,*dst=tmpm->static_data;
  CHashClass *tmpc=tmpm->member_class;
  I64 i,size;
  CAOTImportExport *tmpie;

  if (cc->flags&CCF_AOT_COMPILE && pass==2) {
    (*expression->push)(expression->context,cc);
    (*expression->init)(expression->context,cc);
  }
  PrsVarInit2Core(services,cc,&dst,tmpc,&tmpm->dim,tmpm->static_data_rip,
	&tmpm->static_data,Bt(&cc->flags,CCf_AOT_COMPILE),pass);
  if (cc->flags&CCF_AOT_COMPILE && pass==2) {
    if (cc->coc.coc_head.next!=&cc->coc.coc_head) {
      PrsEmit(expression,cc,IC_RET,0,0);
      if (machine_code=(*services->compile_code)(services->context,cc,&size)) {
	if (pass==2) {
	  tmpie=(*expression->allocate)(expression->context,sizeof(CAOTImportExport),TRUE,FALSE);
	  tmpie->type=IET_MAIN;
	  tmpie->rip=cc->aotc->rip;
	  tmpie->next=&cc->aot->next_ie; tmpie->last=cc->aot->last_ie;
	    cc->aot->last_ie->next=tmpie; cc->aot->last_ie=tmpie;
	  for (i=0;i<size;i++)
	    (*services->store_u8)(services->context,cc,machine_code[i]);
	}
	(*declarations->release)(declarations->context,machine_code);
      }
    } //TODO: else del misc?
    (*expression->pop)(expression->context,cc);
  }
}
