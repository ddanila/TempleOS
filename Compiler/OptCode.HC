CCodeMisc *OptLabelFwd(CCodeMisc *lb)
{
  CCodeMisc *lb1;
  while (lb1=lb->fwd)
    lb=lb1;
  return lb;
}

CHashClass *OptClassFwd(CHashClass *tmpc)
{//Class forwarding for unions and subclasses.
  CHashClass *tmpc1;
  while (tmpc1=tmpc->fwd_class)
    tmpc=tmpc1;
  return tmpc;
}

U0 OptSetNOP1(CIntermediateCode *tmpi)
{
  tmpi->ic_code=IC_NOP1;
  tmpi->ic_flags=0;
  tmpi->arg1.type=MDF_NULL+tmpi->arg1.type.raw_type;
  tmpi->res.type =MDF_NULL+tmpi->res.type.raw_type;
}

U0 OptSetNOP2(CIntermediateCode *tmpi,I64 stk_delta=1)
{
  tmpi->ic_code=IC_NOP2;
  tmpi->ic_data=stk_delta;
  tmpi->arg1.type=MDF_NULL+tmpi->arg1.type.raw_type;
  tmpi->res.type =MDF_NULL+tmpi->res.type.raw_type;
}

CIntermediateCode *OptLag(CIntermediateCode *tmpi)
{
  do {
    if (!tmpi->ic_code)
      return 0;
    else
      tmpi=tmpi->last;
  } while (tmpi->ic_code<=IC_END_EXP);
  return tmpi;
}

CIntermediateCode *OptLag1(CIntermediateCode *tmpi)
{
  do {
    if (!tmpi->ic_code)
      return 0;
    else
      tmpi=tmpi->last;
  } while (tmpi->ic_code==IC_NOP1||tmpi->ic_code==IC_NOP2);
  return tmpi;
}

CIntermediateCode *OptLag2(CIntermediateCode *tmpi)
{
  do {
    if (!tmpi->ic_code)
      return 0;
    else
      tmpi=tmpi->last;
  } while (tmpi->ic_code<IC_END_EXP);
  return tmpi;
}

CIntermediateCode *OptLead1(CIntermediateCode *tmpi)
{
  do {
    tmpi=tmpi->next;
    if (!tmpi->ic_code)
      return 0;
  } while (tmpi->ic_code==IC_NOP1||tmpi->ic_code==IC_NOP2);
  return tmpi;
}

