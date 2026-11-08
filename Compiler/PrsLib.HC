#include "/Compiler/PrsStack.HC"
#include "/Compiler/PrsKeyword.HC"

#include "/Compiler/SymbolInit.HC"
CHashClass *PrsClassNew()
{
  CHashClass *res=CAlloc(sizeof(CHashClass)*(PTR_STARS_NUM+1),Fs->code_heap);
  PrsClassInit(res);
  return res;
}

CHashFun *PrsFunNew()
{
  CHashFun *res=CAlloc(sizeof(CHashFun)*(PTR_STARS_NUM+1),Fs->code_heap);
  PrsFunInit(res);
  return res;
}

#include "/Compiler/PublicCodeCore.HC"

#include "/Compiler/CodeLabel.HC"

I64 COCFloatConstFind(CCmpCtrl *cc,F64 d)
{
  I64 i;
  CCodeMisc *cm=cc->coc.coc_next_misc;
  while (cm!=&cc->coc.coc_next_misc) {
    if (cm->type==CMT_FLOAT_CONSTS) {
      for (i=0;i<cm->num_consts;i++)
	if (cm->float_consts[i]==d)
	  return cm->addr+i*sizeof(F64);
      if (cm->num_consts<CM_CONSTS_NUM)  {
	cm->float_consts[cm->num_consts++]=d;
	return cm->addr+i*sizeof(F64);
      }
    }
    cm=cm->next;
  }
  cm=COCMiscNew(cc,CMT_FLOAT_CONSTS);
  cm->float_consts=MAlloc(CM_CONSTS_NUM*sizeof(F64));
  cm->float_consts[cm->num_consts++]=d;
  return cm->addr;
}

U0 COCHeaderPut(CCmpCtrl *cc,I64 pass,Bool put)
{
  CIntermediateCode *tmpi;
  if (Bt(&cc->flags,CCf_PASS_TRACE_PRESENT)) {
    if (put) {
      if (Bt(&cc->saved_pass_trace,pass-1)) {
	"$$IV,1$$Pass %d:$$IV,0$$\n",pass-1;
	tmpi=cc->coc.coc_head.next;
	while (tmpi->ic_code) {
	  if (tmpi->ic_flags&ICF_PASS_TRACE)
	    ICPut(cc,tmpi);
	  tmpi=tmpi->next;
	}
      }
    } else if (Bt(&cc->saved_pass_trace,pass))
      "$$IV,1$$Pass %d:$$IV,0$$\n",pass;
  }
  cc->pass=pass;
}

#include "/Compiler/TargetSize.HC"

U8 *COCCompile(CCmpCtrl *cc,I64 *_code_size,CDbgInfo **_dbg,I64 *_type)
{
  U8 *res;
  CCodeMisc *lb;
  I64 i,code_size,last_code_size;

  COptReg reg_offsets[REG_REGS_NUM];
  if (cc->flags&CCF_TARGET_I386)
    return I386COCCompile(cc,_code_size,_dbg,_type);
  if (_dbg) *_dbg=NULL;
  cc->pass=0;
  COCHeaderPut(cc,1,TRUE);
  OptPass012(cc);
  COCHeaderPut(cc,2,TRUE);
  OptPass012(cc);
  COCHeaderPut(cc,3,TRUE);
  OptPass3(cc,reg_offsets);
  COCHeaderPut(cc,4,TRUE);
  OptPass4(cc,reg_offsets,_type);
  COCHeaderPut(cc,5,TRUE);
  OptPass5(cc);
  COCHeaderPut(cc,6,TRUE);
  OptPass6(cc);
  COCHeaderPut(cc,7,TRUE);

  lb=cc->coc.coc_next_misc;
  while (lb!=&cc->coc.coc_next_misc) {
    if (lb->type==CMT_JMP_TABLE) {
      for (i=0;i<lb->range;i++)
	lb->jmp_table[i]=OptLabelFwd(lb->jmp_table[i]);
      lb->dft=OptLabelFwd(lb->dft);
    }
    lb=lb->next;
  }

  COCHeaderPut(cc,7,FALSE);
  OptPass789A(cc,reg_offsets,NULL,NULL);
  COCHeaderPut(cc,8,FALSE);
  OptPass789A(cc,reg_offsets,NULL,NULL);
  COCHeaderPut(cc,9,FALSE);
  code_size=OptPass789A(cc,reg_offsets,NULL,NULL);
  do {
    last_code_size=code_size;
    COCHeaderPut(cc,9,FALSE);
    code_size=OptPass789A(cc,reg_offsets,NULL,NULL);
    if (code_size>last_code_size) {
      "Pass:9 Code Size\n";
      LexExcept(cc,"Compiler Optimization Error at ");
    }
  } while (code_size<last_code_size);

  if (cc->flags&CCF_AOT_COMPILE)
    res=MAlloc(code_size);
  else {
    res=MAlloc(code_size,Fs->code_heap);
    if (cc->htc.fun)
      Fs->last_fun=cc->htc.fun;
  }
  COCHeaderPut(cc,10,FALSE);
  code_size=OptPass789A(cc,reg_offsets,res,_dbg);

  COCDel(cc,&cc->coc);
  if (Bt(&cc->opts,OPTf_TRACE)) {
    if (cc->flags&CCF_AOT_COMPILE) {
      if (cc->aotc->seg_size==16)
	Un(res,code_size,16);
      else if (cc->aotc->seg_size==64)
	Un(res,code_size,64);
      else
	Un(res,code_size,32);
    } else
      Un(res,code_size,64);
  }
  if (_code_size) *_code_size=code_size;
  cc->saved_pass_trace=cc->pass_trace;
  return res;
}

#include "/Compiler/I386DataRangeCore.HC"
