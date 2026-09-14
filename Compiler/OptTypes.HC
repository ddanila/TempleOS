#define FBO1_NOT_CONST	0
#define FBO1_INT	1
#define FBO1_F64	2

Bool OptFixupBinaryOp1(CHashClass **types,CIntermediateCode *tmpi,
     CIntermediateCode *tmpi1,CIntermediateCode *tmpi2,
     Bool *is_unsigned)
{
  CIntermediateCode *tmpii;
  CHashClass *tmpc=tmpi->ic_class,*tmpc1,*tmpc2;

  if (tmpi1->ic_flags&ICF_RES_TO_INT)
    tmpc1=types[RT_I64];
  else if (tmpi1->ic_flags&ICF_RES_TO_F64)
    tmpc1=types[RT_F64];
  else {
    tmpc1=OptClassFwd(tmpi1->ic_class);
  }

  if (tmpi2->ic_flags&ICF_RES_TO_INT)
    tmpc2=types[RT_I64];
  else if (tmpi2->ic_flags&ICF_RES_TO_F64)
    tmpc2=types[RT_F64];
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
      tmpi1->ic_class=types[RT_F64];
      tmpi1->ic_code=IC_IMM_F64;
      tmpi1->ic_flags&=~ICF_RES_TO_F64;
    } else
      if (tmpc1->raw_type!=RT_F64)
	tmpi1->ic_flags|=ICF_RES_TO_F64;
    if (tmpi2->ic_code==IC_IMM_I64) {
      tmpi2->ic_data(F64)=tmpi2->ic_data;
      tmpi2->ic_class=types[RT_F64];
      tmpi2->ic_code=IC_IMM_F64;
      tmpi2->ic_flags&=~ICF_RES_TO_F64;
    } else
      if (tmpc2->raw_type!=RT_F64)
	tmpi2->ic_flags|=ICF_RES_TO_F64;
    if (IC_LESS<=tmpi->ic_code<=IC_GREATER_EQU && (tmpii=OptLead1(tmpi)) &&
	  tmpii->ic_code!=IC_PUSH_CMP && tmpii->ic_code!=IC_AND_AND) {
//We are looking for float comparisons to zero to convert to int.
      if (tmpi1->ic_code==IC_IMM_F64 && !tmpi1->ic_data &&
	    tmpi2->ic_code==IC_DEREF && tmpc2==types[RT_F64]) {
	tmpi1->ic_code==IC_IMM_I64;
	goto fb_here1;
      } else if (tmpi2->ic_code==IC_IMM_F64 && !tmpi2->ic_data &&
	    tmpi1->ic_code==IC_DEREF && tmpc1==types[RT_F64]) {
	tmpi2->ic_code==IC_IMM_I64;
fb_here1:
	tmpi1->ic_flags&=~ICF_RES_TO_F64;
	tmpi->ic_class=tmpi1->ic_class=tmpi2->ic_class=
	      types[RT_I64];
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

Bool OptFixupUnaryOp(CHashClass **types,CIntermediateCode *tmpi, CIntermediateCode *tmpi1,
     Bool *is_unsigned)
{
  CHashClass *tmpc,*tmpc1;
  tmpc1=OptClassFwd(tmpi1->ic_class);
  tmpi->ic_class=tmpc1;
  tmpc=tmpi->ic_class;
  if (tmpc->raw_type==RT_F64) {
    if (tmpi1->ic_code==IC_IMM_I64) {
      tmpi1->ic_data(F64)=tmpi1->ic_data;
      tmpi1->ic_class=types[RT_F64];
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

