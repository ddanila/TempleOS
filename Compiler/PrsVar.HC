U0 PrsVarInit(CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,CArrayDim *tmpad,
	U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass)
{
  U8 *dst=*_dst,*machine_code;
  I64 i,j,r,old_flags,type,size;
  CMemberLst *tmpm;
  CIntermediateCode *tmpi;
  CAOTCtrl *aotc=cc->aotc;
  CAOTAbsAddr *tmpa;
  CAOTImportExport *tmpie;
  Bool is_str;

  tmpc=OptClassFwd(tmpc);
  if (tmpm=tmpc->member_lst_and_root) {
    if (cc->token!='{')
      LexExcept(cc,"Expecting '{' at ");
    LexPopNoRestore(cc);
    LexPush(cc);
    Lex(cc);
    while (tmpm) {
      PrsVarInit2(cc,&dst,tmpm->member_class,&tmpm->dim,
	    data_addr_rip,_base,data_heap,pass);
      if (cc->token==',')
	Lex(cc);
      tmpm=tmpm->next;
    }
    LexPopNoRestore(cc);
    if (cc->token!='}')
      LexExcept(cc,"Missing '}' at ");
    Lex(cc);
  } else {
    if (tmpc->ptr_stars_cnt==1 &&
	  ((tmpc-1)->raw_type==RT_I8 || (tmpc-1)->raw_type==RT_U8) &&
	  !tmpad && cc->token==TK_STR)
      is_str=TRUE;
    else
      is_str=FALSE;
    if (cc->flags&CCF_TARGET_I386 && is_str) throw('Compiler');
    if (cc->flags&CCF_AOT_COMPILE && is_str) {
      LexPopNoRestore(cc);
      machine_code=LexExtStr(cc,&i);
      if (pass==2) {
	tmpa=CAlloc(sizeof(CAOTAbsAddr));
	tmpa->next=aotc->abss;
	tmpa->type=AAT_ADD_U64;
	aotc->abss=tmpa;
	tmpa->rip=data_addr_rip+dst-*_base;
	*dst(I64 *)=aotc->rip;
	for (j=0;j<i;j++)
	  AOTStoreCodeU8(cc,machine_code[j]);
      }
      Free(machine_code);
    } else {
      old_flags=cc->flags;
      cc->flags=CCF_NO_ABSS | cc->flags &
	    ~(CCF_AOT_COMPILE|CCF_HAS_MISC_DATA|CCF_NOT_CONST);
      machine_code=LexExpression2Bin(cc,&type);
      if (old_flags&CCF_AOT_COMPILE &&
	    cc->flags&CCF_NOT_CONST &&
	    !Bt(&cc->opts,OPTf_GLBLS_ON_DATA_HEAP)) {
	cc->flags=cc->flags&~CCF_NO_ABSS|CCF_AOT_COMPILE;
	Free(machine_code);
	if (pass==2) {
	  MemSet(dst,0,CmpTargetSize(cc,tmpc));
	  LexPopRestore(cc);
	  Lex(cc);
	  COCPush(cc);
	  COCInit(cc);
	  ICAdd(cc,IC_ABS_ADDR,data_addr_rip,tmpc+1);
	  ICAdd(cc,IC_IMM_I64,dst-*_base,tmpc+1);
	  ICAdd(cc,IC_ADD,0,tmpc+1);
	  if (!PrsExpression(cc,NULL,TRUE))
	    throw('Compiler');
	  tmpi=cc->coc.coc_head.last;
	  if (tmpi->ic_code==IC_END_EXP) {
	    tmpi->ic_code=IC_NOP1;
	    tmpi->ic_flags=0;
	  }
	  ICAdd(cc,IC_ASSIGN,0,tmpc);
	  ICAdd(cc,IC_END_EXP,0,tmpc,ICF_RES_NOT_USED);
	  ICAdd(cc,IC_RET,0,0);
	  if (machine_code=COCCompile(cc,&size,NULL,NULL)) {
	    tmpie=CAlloc(sizeof(CAOTImportExport));
	    tmpie->type=IET_MAIN;
	    tmpie->rip=cc->aotc->rip;
	    QueIns(tmpie,cc->aot->last_ie);
	    for (i=0;i<size;i++)
	      AOTStoreCodeU8(cc,machine_code[i]);
	    Free(machine_code);
	  }
	  COCPop(cc);
	} else
	  LexPopNoRestore(cc);
      } else {
	LexPopNoRestore(cc);
	if (!machine_code)
	  throw('Compiler');
	r=Call(machine_code);
	if (!(cc->flags & CCF_HAS_MISC_DATA)||pass==1)
	  Free(machine_code);

	if (type==RT_F64 &&
	      tmpc->raw_type!=RT_F64)
	  r=r(F64);
	else if (type!=RT_F64 &&
	      tmpc->raw_type==RT_F64)
	  r(F64)=r;
	MemCpy(dst,&r,CmpTargetSize(cc,tmpc));
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

U0 PrsVarInit2(CCmpCtrl *cc,U8 **_dst,CHashClass *tmpc,
	CArrayDim *tmpad,U8 *data_addr_rip,U8 **_base,Bool data_heap,I64 pass)
{
  I64 i,j,cnt;
  U8 *st,*_b;
  CVI2 head,*tmpvi,*tmpvi1;
  CArrayDim *tmpad1;
  tmpc=OptClassFwd(tmpc);
  if (tmpad1=tmpad->next) {
    if (!tmpc->ptr_stars_cnt &&
	  (tmpc->raw_type==RT_I8 || tmpc->raw_type==RT_U8) &&
	  cc->token==TK_STR) {
      LexPopNoRestore(cc);
      st=LexExtStr(cc,&i);
      if (tmpad1->cnt<0) {//[]
	tmpad1->cnt=i;
	tmpad->total_cnt=i*tmpad1->total_cnt;
	Free(*_base);
	if (data_heap)
	  *_base=MAlloc(i);
	else
	  *_base=MAlloc(i,Fs->code_heap);
	MemCpy(*_base,st,i);
	*_dst=*_base+i;
      } else {
	MemCpy(*_dst,st,tmpad1->cnt);
	*_dst+=tmpad1->cnt;
      }
      Free(st);
      LexPush(cc);
    } else {
      if (cc->token=='{') {
	LexPopNoRestore(cc);
	LexPush(cc);
	Lex(cc);
      }
      if (tmpad1->cnt<0) {//[]
	QueInit(&head);
	cnt=0;
	while (cc->token!='}') {
	  tmpvi=MAlloc(offset(CVI2.base)+tmpad1->total_cnt*CmpTargetSize(cc,tmpc));
	  _b=&tmpvi->base;
	  PrsVarInit2(cc,&_b,tmpc,tmpad1,data_addr_rip,_base,data_heap,pass);
	  QueIns(tmpvi,head.last);
	  if (cc->token==',')
	    Lex(cc);
	  cnt++;
	}
	Lex(cc); //skip '}'
	tmpad1->cnt=cnt;
	tmpad->total_cnt=cnt*tmpad1->total_cnt;
	j=tmpad1->total_cnt*CmpTargetSize(cc,tmpc);
	i=cnt*j;
	Free(*_base);
	if (data_heap)
	  *_base=_b=MAlloc(i);
	else
	  *_base=_b=MAlloc(i,Fs->code_heap);
	tmpvi=head.next;
	while (tmpvi!=&head) {
	  tmpvi1=tmpvi->next;
	  MemCpy(_b,&tmpvi->base,j);
	  _b+=j;
	  Free(tmpvi);
	  tmpvi=tmpvi1;
	}
	*_dst=_b;
      } else {
	for (i=0;i<tmpad1->cnt;i++) {
	  PrsVarInit2(cc,_dst,tmpc,tmpad1,data_addr_rip,_base,data_heap,pass);
	  if (tmpad1->cnt>1 && cc->token==',')
	    Lex(cc);
	}
	if (cc->token=='}')
	  Lex(cc);
      }
    }
  } else {
    PrsVarInit(cc,_dst,tmpc,tmpad1,data_addr_rip,_base,data_heap,pass);
    LexPush(cc);
  }
}

U0 PrsGlblInit(CCmpCtrl *cc,CHashGlblVar *tmpg,I64 pass)
{
  U8 *dst=tmpg->data_addr;
  PrsVarInit2(cc,&dst,tmpg->var_class,&tmpg->dim,
	tmpg->data_addr_rip,&tmpg->data_addr,
	Bt(&cc->opts,OPTf_GLBLS_ON_DATA_HEAP)||
	Bt(&cc->flags,CCf_AOT_COMPILE),pass);
}

U0 PrsStaticInit(CCmpCtrl *cc,CMemberLst *tmpm,I64 pass)
{
  U8 *machine_code,*dst=tmpm->static_data;
  CHashClass *tmpc=tmpm->member_class;
  I64 i,size;
  CAOTImportExport *tmpie;

  if (cc->flags&CCF_AOT_COMPILE && pass==2) {
    COCPush(cc);
    COCInit(cc);
  }
  PrsVarInit2(cc,&dst,tmpc,&tmpm->dim,tmpm->static_data_rip,
	&tmpm->static_data,Bt(&cc->flags,CCf_AOT_COMPILE),pass);
  if (cc->flags&CCF_AOT_COMPILE && pass==2) {
    if (cc->coc.coc_head.next!=&cc->coc.coc_head) {
      ICAdd(cc,IC_RET,0,0);
      if (machine_code=COCCompile(cc,&size,NULL,NULL)) {
	if (pass==2) {
	  tmpie=CAlloc(sizeof(CAOTImportExport));
	  tmpie->type=IET_MAIN;
	  tmpie->rip=cc->aotc->rip;
	  QueIns(tmpie,cc->aot->last_ie);
	  for (i=0;i<size;i++)
	    AOTStoreCodeU8(cc,machine_code[i]);
	}
	Free(machine_code);
      }
    } //TODO: else del misc?
    COCPop(cc);
  }
}

#include "/Compiler/PrsTypeCore.HC"
U0 PrsHostSnapshotDrop(U8 *context,CCmpCtrl *cc) { LexPopNoRestore(cc); }
U0 PrsHostSnapshotPush(U8 *context,CCmpCtrl *cc) { LexPush(cc); }
I64 PrsHostIntegerExpression(U8 *context,CCmpCtrl *cc) { return LexExpressionI64(cc); }
CHashClass *PrsHostClassJoin(U8 *context,CCmpCtrl *cc,I64 keyword,I64 flags,Bool is_extern)
{ return PrsClass(cc,keyword,flags,is_extern); }
CHashFun *PrsHostFunJoin(U8 *context,CCmpCtrl *cc,CHashClass *return_type,U8 *name,I64 flags)
{ return PrsFunJoin(cc,return_type,name,flags); }
U8 *PrsHostTypeAllocate(U8 *context,I64 bytes) { return MAlloc(bytes); }
CMemberLst *PrsHostMemberNew(U8 *context,I64 register_hint) { return MemberLstNew(register_hint); }
U0 PrsHostMemberAdd(U8 *context,CCmpCtrl *cc,CMemberLst *member,CHashClass *type,I64 mode)
{ MemberAdd(cc,member,type,mode); }
U0 PrsHostTypeServices(CPrsTypeServices *services)
{
  services->context=0; services->types=cmp.internal_types;
  services->lex=&PrsHostLex; services->report=&PrsHostReport;
  services->snapshot_drop=&PrsHostSnapshotDrop; services->snapshot_push=&PrsHostSnapshotPush;
  services->integer_expression=&PrsHostIntegerExpression;
  services->class_join=&PrsHostClassJoin; services->fun_join=&PrsHostFunJoin;
  services->allocate=&PrsHostTypeAllocate; services->duplicate=&PrsHostDuplicate;
  services->member_new=&PrsHostMemberNew; services->member_add=&PrsHostMemberAdd;
}

U0 PrsArrayDims(CCmpCtrl *cc,I64 mode,CArrayDim *dim)
{
  CPrsTypeServices services;
  PrsHostTypeServices(&services);
  PrsArrayDimsCore(&services,cc,mode,dim);
}

CHashClass *PrsType(CCmpCtrl *cc,CHashClass **_tmpc1,
  I64 *_mode,CMemberLst *tmpm,U8 **_ident,CHashFun **_fun_ptr,
  CHashExport **_tmpex,CArrayDim *tmpad,I64 fsp_flags)
{
  CPrsTypeServices services;
  PrsHostTypeServices(&services);
  return PrsTypeCore(&services,cc,_tmpc1,_mode,tmpm,_ident,_fun_ptr,_tmpex,tmpad,fsp_flags);
}

U0 PrsDotDotDot(CCmpCtrl *cc,CHashFun *tmpf,I64 _reg)
{
  CPrsTypeServices services;
  PrsHostTypeServices(&services);
  PrsDotDotDotCore(&services,cc,tmpf,_reg);
}

#include "/Compiler/PrsDeclarationCore.HC"
I64 PrsHostDefineMatch(U8 *context,U8 *name,U8 *list) { return DefineMatch(name,list); }
I64 PrsHostEvaluate(U8 *context,CCmpCtrl *cc) { return LexExpression(cc); }
U0 PrsHostSnapshotRestore(U8 *context,CCmpCtrl *cc) { LexPopRestore(cc); }
U0 PrsHostInitializeStatic(U8 *context,U8 *data,I64 bytes)
{ if(sys_var_init_flag) MemSet(data,sys_var_init_val,bytes); }
U0 PrsHostStaticInit(U8 *context,CCmpCtrl *cc,CMemberLst *member,I64 pass)
{ PrsStaticInit(cc,member,pass); }
U0 PrsHostStoreU64(U8 *context,CCmpCtrl *cc,I64 value) { AOTStoreCodeU64(cc,value); }
U0 PrsHostStoreU8At(U8 *context,CCmpCtrl *cc,I64 address,U8 value)
{ AOTStoreCodeU8At(cc,address,value); }
U0 PrsHostDataRange(U8 *context,CCmpCtrl *cc,I64 address,I64 bytes)
{ PrsI386DataRange(cc,address,bytes); }
U8 *PrsHostCompileExpression(U8 *context,CCmpCtrl *cc,I64 *type)
{ return LexExpression2Bin(cc,type); }
I64 PrsHostExecute(U8 *context,U8 *code) { return Call(code); }
U0 PrsHostRelease(U8 *context,U8 *allocation) { Free(allocation); }
U0 PrsHostDeclarationServices(CPrsDeclarationServices *services,
  CPrsExpressionServices *expression,CPrsTypeServices *types)
{
  services->context=0; services->expression=expression; services->types=types;
  services->define_match=&PrsHostDefineMatch; services->evaluate=&PrsHostEvaluate;
  services->snapshot_restore=&PrsHostSnapshotRestore; services->initialize_static=&PrsHostInitializeStatic;
  services->static_init=&PrsHostStaticInit; services->store_u64=&PrsHostStoreU64;
  services->store_u8_at=&PrsHostStoreU8At; services->data_range=&PrsHostDataRange;
  services->compile_expression=&PrsHostCompileExpression; services->execute=&PrsHostExecute;
  services->release=&PrsHostRelease;
}

U0 PrsVarLst(CCmpCtrl *cc,CHashClass *tmpc,I64 mode,I64 union_base=0)
{
  CPrsExpressionServices expression;
  CPrsTypeServices types;
  CPrsDeclarationServices services;
  PrsHostServices(&expression); PrsHostTypeServices(&types);
  PrsHostDeclarationServices(&services,&expression,&types);
  PrsVarLstCore(&services,cc,tmpc,mode,union_base);
}
