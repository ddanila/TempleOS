#include "/Compiler/OptCode.HC"
CIntermediateCode *OptFree(CCmpCtrl *cc,CIntermediateCode *tmpi)
{//We might access freed entries in CICTreeLinks
  ICDetach(tmpi);
  Free(tmpi);
  return NULL;
}

I64 CmpOffset2Reg(I64 offset,COptReg *reg_offsets)
{
  I64 i;
  for (i=0;i<REG_REGS_NUM;i++)
    if (offset==reg_offsets[i].offset)
      return i;
  return -1;
}

#include "/Compiler/OptTypes.HC"

#include "/Compiler/OptBranch.HC"

#include "/Compiler/OptSize.HC"

I64 CmpRawType(CHashClass *tmpc)
{
  if (tmpc) {
    tmpc=OptClassFwd(tmpc);
    return tmpc->raw_type;
  }
  return 0;
}

I64 CmpRawTypePointed(CHashClass *tmpc)
{
  if (tmpc) {
    if (tmpc->ptr_stars_cnt)
      tmpc--;
    tmpc=OptClassFwd(tmpc);
    return tmpc->raw_type;
  }
  return 0;
}

U0 CmpMinTypePointed(CIntermediateCode *tmpi,I64 pt1)
{
  I64 pt;
  if ((pt=tmpi->arg1_type_pointed_to) && pt!=RT_F64 && 0<pt1<pt)
    tmpi->arg1_type_pointed_to=pt;
}

U0 CmpF1PushPop(CIntermediateCode *tmpi,CIntermediateCode *tmpi2)
{
  if (intermediate_code_table[tmpi2->ic_code].fpop||
	tmpi2->ic_flags&ICF_RES_TO_F64)
    Bts(&tmpi->ic_flags,ICf_DONT_PUSH_FLOAT0);
}

U0 CmpF2PushPop(CIntermediateCode *tmpi,
	CIntermediateCode *tmpi1,CIntermediateCode *tmpi2)
{
  if ((tmpi2->ic_code==IC_MOV || tmpi2->ic_code==IC_IMM_F64) &&
	!(tmpi2->ic_flags&ICF_RES_TO_F64) &&
	(intermediate_code_table[tmpi1->ic_code].fpop ||
	tmpi1->ic_flags&ICF_RES_TO_F64))
    Bts(&tmpi->ic_flags,ICf_DONT_PUSH_FLOAT0);
  else if ((intermediate_code_table[tmpi2->ic_code].fpop ||
	tmpi2->ic_flags&ICF_RES_TO_F64)&&
	!(tmpi1->ic_flags&ICF_RES_TO_F64))
    Bts(&tmpi->ic_flags,ICf_DONT_PUSH_FLOAT0);
}

class COptMemberVar
{
  I64 score,offset_start,offset_end,lea_balance;
  CMemberLst *m;
};

I64 OptMVCompare(COptMemberVar *mv1,COptMemberVar *mv2)
{
  return mv2->score-mv1->score;
}
