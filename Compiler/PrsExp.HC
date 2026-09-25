//Host services for the shared HolyC expression parser.
#include "/Compiler/PrsExpressionCore.HC"
extern Bool PrsExpression(CCmpCtrl *cc,I64 *_max_prec,Bool end_exp,CPrsStk *_ps=NULL);
I64 PrsHostLex(U8 *context,CCmpCtrl *cc) { return Lex(cc); }
U0 PrsHostReport(U8 *context,CCmpCtrl *cc,I64 kind,U8 *message)
{
  if(kind==0) LexExcept(cc,message);
  else if(kind==1) LexWarn(cc,message);
  else ParenWarning(cc);
}
CIntermediateCode *PrsHostAdd(U8 *context,CCmpCtrl *cc,I64 op,I64 value,CHashClass *type,I64 flags)
{ return ICAdd(cc,op,value,type,flags); }
U0 PrsHostRetire(U8 *context,CCmpCtrl *cc,CIntermediateCode *node) { OptFree(cc,node); }
CCodeMisc *PrsHostMisc(U8 *context,CCmpCtrl *cc,I64 kind) { return COCMiscNew(cc,kind); }
U0 PrsHostInit(U8 *context,CCmpCtrl *cc) { COCInit(cc); }
U0 PrsHostPush(U8 *context,CCmpCtrl *cc) { COCPush(cc); }
U0 PrsHostPop(U8 *context,CCmpCtrl *cc) { COCPop(cc); }
U0 PrsHostAppend(U8 *context,CCmpCtrl *cc,CCodeCtrl *saved) { COCAppend(cc,saved); }
CIntermediateCode *PrsHostOptimize(U8 *context,CCmpCtrl *cc) { return OptPass012(cc); }
U8 *PrsHostAllocate(U8 *context,I64 size,Bool zeroed,Bool code_heap)
{
  if(zeroed) { if(code_heap) return CAlloc(size,Fs->code_heap); return CAlloc(size); }
  if(code_heap) return MAlloc(size,Fs->code_heap);
  return MAlloc(size);
}
U8 *PrsHostDuplicate(U8 *context,U8 *source) { return StrNew(source); }
U8 *PrsHostString(U8 *context,CCmpCtrl *cc,I64 *length) { return LexExtStr(cc,length); }
U0 PrsHostHashAdd(U8 *context,CHash *entry,CHashTable *table) { HashAdd(entry,table); }
U0 PrsHostHashAfter(U8 *context,CHash *entry,CHash *after,CHashTable *table) { HashAddAfter(entry,after,table); }
CHashClass *PrsHostType(U8 *context,CCmpCtrl *cc,CHashClass **first,I64 *mode,
  CMemberLst *member,U8 **ident,CHashFun **fun,CHashExport **export_entry,CArrayDim *dim,I64 flags)
{ return PrsType(cc,first,mode,member,ident,fun,export_entry,dim,flags); }
Bool PrsHostExpression(U8 *context,CCmpCtrl *cc,I64 *precedence,Bool end_exp,CPrsStk *stack)
{ return PrsExpression(cc,precedence,end_exp,stack); }
U0 PrsHostServices(CPrsExpressionServices *services)
{
  services->context=0; services->types=cmp.internal_types; services->binary_ops=cmp.binary_ops;
  services->lex=&PrsHostLex; services->report=&PrsHostReport; services->add=&PrsHostAdd;
  services->retire=&PrsHostRetire; services->misc=&PrsHostMisc; services->init=&PrsHostInit;
  services->push=&PrsHostPush; services->pop=&PrsHostPop; services->append=&PrsHostAppend;
  services->optimize=&PrsHostOptimize; services->allocate=&PrsHostAllocate;
  services->duplicate=&PrsHostDuplicate; services->string=&PrsHostString;
  services->hash_add=&PrsHostHashAdd; services->hash_after=&PrsHostHashAfter;
  services->class_view=0;
  services->retain_function_addresses=FALSE;
  services->retain_data_addresses=FALSE;
  services->type=&PrsHostType; services->expression=&PrsHostExpression;
}

CIntermediateCode *PrsAddOp(CCmpCtrl *cc,I64 stk_op,CHashClass *tmpc)
{
  CPrsExpressionServices services;
  PrsHostServices(&services);
  return PrsAddOpCore(&services,cc,stk_op,tmpc);
}

U0 PrsExpression2(CCmpCtrl *cc,I64 *_max_prec,CPrsStk *ps)
{
  CPrsExpressionServices services;
  PrsHostServices(&services);
  PrsExpression2Core(&services,cc,_max_prec,ps);
}

U0 PrsSizeOf(CCmpCtrl *cc)
{
  CPrsExpressionServices services;
  PrsHostServices(&services);
  PrsSizeOfCore(&services,cc);
}

U0 PrsOffsetOf(CCmpCtrl *cc)
{
  CPrsExpressionServices services;
  PrsHostServices(&services);
  PrsOffsetOfCore(&services,cc);
}

I64 PrsFunCall(CCmpCtrl *cc,CPrsStk *ps,Bool indirect,CHashFun *tmpf)
{
  CPrsExpressionServices services;
  PrsHostServices(&services);
  return PrsFunCallCore(&services,cc,ps,indirect,tmpf);
}

I64 PrsUnaryTerm(CCmpCtrl *cc,CPrsStk *ps,CMemberLst **_local_var,
	CArrayDim **_tmpad,I64 *max_prec,I64 *unary_pre_prec,I64 *paren_prec)
{
  CPrsExpressionServices services;
  PrsHostServices(&services);
  return PrsUnaryTermCore(&services,cc,ps,_local_var,_tmpad,max_prec,unary_pre_prec,paren_prec);
}

I64 PrsUnaryModifier(CCmpCtrl *cc,CPrsStk *ps,CMemberLst **_local_var,
	CArrayDim **_tmpad,I64 *unary_post_prec)
{
  CPrsExpressionServices services;
  PrsHostServices(&services);
  return PrsUnaryModifierCore(&services,cc,ps,_local_var,_tmpad,unary_post_prec);
}

Bool PrsExpression(CCmpCtrl *cc,I64 *_max_prec,Bool end_exp,CPrsStk *_ps=NULL)
{
  CPrsExpressionServices services;
  Bool res=TRUE;
  I64 old_flags=cc->flags;
  CPrsStk *ps;
  PrsHostServices(&services);
  if (_ps)
    ps=_ps;
  else {
    ps=MAlloc(sizeof(CPrsStk));
    ps->ptr=0;
    ps->ptr2=0;
  }
  PrsPush(ps,0); //terminate
  PrsPush(ps,0); //terminate
  try
//try catch causes noreg vars in function
	  PrsExpression2Core(&services,cc,_max_prec,ps);
  catch {
    if (Fs->except_ch=='Compiler') {
      res=FALSE;
      Fs->catch_except=TRUE;
    }
  }
  if (!_ps) {
    if (ps->ptr)
      LexExcept(cc,"Compiler Parse Error at ");
    Free(ps);
  }
  if (res) {
    if (end_exp)
      ICAdd(cc,IC_END_EXP,0,0,ICF_RES_NOT_USED);
    if (cc->coc.coc_head.last->ic_class==
	  cmp.internal_types[RT_U0])
      LexWarn(cc,"U0 Expression ");
  }
  cc->flags|=old_flags&(CCF_PREINC|CCF_PREDEC);
  return res;
}

U8 *LexExpression2Bin(CCmpCtrl *cc,I64 *_type=NULL)
{//Compile cc expression. You call the code.
  U8 *res;
  I64 size;
  Bool old_trace=Btr(&cc->flags,CCf_PASS_TRACE_PRESENT);
  COCPush(cc);
  COCInit(cc);
  if (PrsExpression(cc,NULL,FALSE)) {
    ICAdd(cc,IC_RETURN_VAL,0,0);
    ICAdd(cc,IC_RET,0,0);
    if (cc->flags&CCF_TARGET_I386) cc->flags|=CCF_TARGET_HOST_CONST;
    res=COCCompile(cc,&size,NULL,_type);
    cc->flags&=~CCF_TARGET_HOST_CONST;
  } else
    res=NULL;
  COCPop(cc);
  BEqu(&cc->flags,CCf_PASS_TRACE_PRESENT,old_trace);
  return res;
}

Bool IsLexExpression2Bin(CCmpCtrl *cc,U8 **_machine_code)
{//Compile cc expression to bin. Return err status.
  return ToBool(*_machine_code=LexExpression2Bin(cc));
}

I64 LexExpressionI64(CCmpCtrl *cc)
{//Compile cc expression, forcing to I64 and eval.
  U8 *machine_code;
  I64 res,type;
  if (machine_code=LexExpression2Bin(cc,&type)) {
    res=Call(machine_code);
    Free(machine_code);
    if (type==RT_F64)
      res=ToI64(res(F64));
  } else
    res=0;
  return res;
}

F64 LexExpressionF64(CCmpCtrl *cc)
{//Compile cc expression, forcing to F64 and eval.
  U8 *machine_code;
  I64 res,type;
  if (machine_code=LexExpression2Bin(cc,&type)) {
    res=Call(machine_code);
    Free(machine_code);
    if (type!=RT_F64)
      res(F64)=ToF64(res);
  } else
    res=0;
  return res(F64);
}

I64 LexExpression(CCmpCtrl *cc)
{//Compile cc expression and eval.  Might be I64 or F64.
  U8 *machine_code;
  I64 res;
  if (machine_code=LexExpression2Bin(cc)) {
    res=Call(machine_code);
    Free(machine_code);
  } else
    res=0;
  return res;
}
