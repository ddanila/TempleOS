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

#define FBO1_NOT_CONST	0
#define FBO1_INT	1
#define FBO1_F64	2

Bool OptFixupBinaryOp1(CIntermediateCode *tmpi,
     CIntermediateCode *tmpi1,CIntermediateCode *tmpi2,
     Bool *is_unsigned)
{
  CIntermediateCode *tmpii;
  CHashClass *tmpc=tmpi->ic_class,*tmpc1,*tmpc2;

  if (tmpi1->ic_flags&ICF_RES_TO_INT)
    tmpc1=cmp.internal_types[RT_I64];
  else if (tmpi1->ic_flags&ICF_RES_TO_F64)
    tmpc1=cmp.internal_types[RT_F64];
  else {
    tmpc1=OptClassFwd(tmpi1->ic_class);
  }

  if (tmpi2->ic_flags&ICF_RES_TO_INT)
    tmpc2=cmp.internal_types[RT_I64];
  else if (tmpi2->ic_flags&ICF_RES_TO_F64)
    tmpc2=cmp.internal_types[RT_F64];
  else {
    tmpc2=OptClassFwd(tmpi2->ic_class);
  }

  if (tmpc1->raw_type>tmpc2->raw_type)
    tmpc=tmpi->ic_class=tmpc1;
  else
    tmpc=tmpi->ic_class=tmpc2;

  if (tmpc->raw_type==RT_F64) {
    if (tmpi1->ic_code==IC_IMM_I64) {
      tmpi1->ic_data(F64)=tmpi1->ic_data;
      tmpi1->ic_class=cmp.internal_types[RT_F64];
      tmpi1->ic_code=IC_IMM_F64;
      tmpi1->ic_flags&=~ICF_RES_TO_F64;
    } else
      if (tmpc1->raw_type!=RT_F64)
	tmpi1->ic_flags|=ICF_RES_TO_F64;
    if (tmpi2->ic_code==IC_IMM_I64) {
      tmpi2->ic_data(F64)=tmpi2->ic_data;
      tmpi2->ic_class=cmp.internal_types[RT_F64];
      tmpi2->ic_code=IC_IMM_F64;
      tmpi2->ic_flags&=~ICF_RES_TO_F64;
    } else
      if (tmpc2->raw_type!=RT_F64)
	tmpi2->ic_flags|=ICF_RES_TO_F64;
    if (IC_LESS<=tmpi->ic_code<=IC_GREATER_EQU && (tmpii=OptLead1(tmpi)) &&
	  tmpii->ic_code!=IC_PUSH_CMP && tmpii->ic_code!=IC_AND_AND) {
//We are looking for float comparisons to zero to convert to int.
      if (tmpi1->ic_code==IC_IMM_F64 && !tmpi1->ic_data &&
	    tmpi2->ic_code==IC_DEREF && tmpc2==cmp.internal_types[RT_F64]) {
	tmpi1->ic_code==IC_IMM_I64;
	goto fb_here1;
      } else if (tmpi2->ic_code==IC_IMM_F64 && !tmpi2->ic_data &&
	    tmpi1->ic_code==IC_DEREF && tmpc1==cmp.internal_types[RT_F64]) {
	tmpi2->ic_code==IC_IMM_I64;
fb_here1:
	tmpi1->ic_flags&=~ICF_RES_TO_F64;
	tmpi->ic_class=tmpi1->ic_class=tmpi2->ic_class=
	      cmp.internal_types[RT_I64];
	*is_unsigned=FALSE;
	return FBO1_NOT_CONST;
      }
      goto fb_here2;
    } else {
fb_here2:
      if (tmpi1->ic_code==IC_IMM_F64 && tmpi2->ic_code==IC_IMM_F64 &&
	    !(tmpi->ic_flags&(ICF_PUSH_CMP|ICF_POP_CMP))) {
	tmpi->ic_flags|=tmpi1->ic_flags|tmpi2->ic_flags;
	OptSetNOP1(tmpi1);
	OptSetNOP1(tmpi2);
	return FBO1_F64;
      } else
	return FBO1_NOT_CONST;
    }
  }
  *is_unsigned=tmpc1->raw_type&RTF_UNSIGNED || tmpc2->raw_type&RTF_UNSIGNED;
  if (tmpi1->ic_code==IC_IMM_I64 && tmpi2->ic_code==IC_IMM_I64 &&
	!(tmpi->ic_flags&(ICF_PUSH_CMP|ICF_POP_CMP))) {
    tmpi->ic_flags|=tmpi1->ic_flags|tmpi2->ic_flags;
    OptSetNOP1(tmpi1);
    OptSetNOP1(tmpi2);
    return FBO1_INT;
  } else
    return FBO1_NOT_CONST;
}

Bool OptFixupBinaryOp2(CIntermediateCode **tmpi1,CIntermediateCode **tmpi2)
{
  CIntermediateCode *tmpii1=*tmpi1,
	*tmpii2=*tmpi2;
  if (tmpii1->ic_code==IC_IMM_I64 && !(tmpii1->ic_flags & ICF_RES_TO_F64))
    return TRUE;
  if (tmpii2->ic_code==IC_IMM_I64 && !(tmpii2->ic_flags & ICF_RES_TO_F64)) {
    *tmpi1=tmpii2;
    *tmpi2=tmpii1;
    return TRUE;
  }
  return FALSE;
}

Bool OptFixupUnaryOp(CIntermediateCode *tmpi, CIntermediateCode *tmpi1,
     Bool *is_unsigned)
{
  CHashClass *tmpc,*tmpc1;
  tmpc1=OptClassFwd(tmpi1->ic_class);
  tmpi->ic_class=tmpc1;
  tmpc=tmpi->ic_class;
  if (tmpc->raw_type==RT_F64) {
    if (tmpi1->ic_code==IC_IMM_I64) {
      tmpi1->ic_data(F64)=tmpi1->ic_data;
      tmpi1->ic_class=cmp.internal_types[RT_F64];
      tmpi1->ic_code=IC_IMM_F64;
      tmpi1->ic_flags&=~ICF_RES_TO_F64;
    } else
      if (tmpc1->raw_type!=RT_F64)
	tmpi1->ic_flags|=ICF_RES_TO_F64;
    if (tmpi1->ic_code==IC_IMM_F64) {
      tmpi->ic_flags|=tmpi1->ic_flags;
      OptSetNOP1(tmpi1);
      return FBO1_F64;
    } else
      return FBO1_NOT_CONST;
  }
  *is_unsigned=tmpc1->raw_type&RTF_UNSIGNED;
  if (tmpi1->ic_code==IC_IMM_I64) {
    tmpi->ic_flags|=tmpi1->ic_flags;
    OptSetNOP1(tmpi1);
    return FBO1_INT;
  } else
    return FBO1_NOT_CONST;
}

#include "/Compiler/OptBranch.HC"

U0 OptFixSizeOf(CCmpCtrl *cc,CIntermediateCode *tmpi1,
	CIntermediateCode *tmpi_push,CHashClass *tmpcc)
{
  if (tmpi1->ic_code==IC_MUL && tmpi1->t.arg2_tree->ic_code==IC_SIZEOF) {
    tmpi1->t.arg2_tree->ic_code=IC_IMM_I64;
    tmpi1->t.arg2_tree->ic_class=tmpcc;
    tmpi_push->ic_class=tmpcc;
    if (tmpcc->ptr_stars_cnt) {
      tmpcc--;
      if (CmpTargetSize(cc,tmpcc)==1)
	goto here;
      tmpi1->t.arg2_tree->ic_data=CmpTargetSize(cc,tmpcc);
    } else {
here:
      if (tmpi_push==tmpi1)
	tmpi1->t.arg2_tree->ic_data=1;
      else {
	OptSetNOP1(tmpi1->t.arg2_tree);
	OptSetNOP1(tmpi1);
      }
    }
  }
}

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
