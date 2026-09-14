#include "/Compiler/SymbolInit.HH"
//Caller supplies PTR_STARS_NUM+1 fresh, zeroed records, with stable lifetime.
//Pointer variants advance by a complete record, not by a machine-word slot.
U0 PrsClassInit(CHashClass *res)
{
  I64 i;
  CHashClass *tmpc=res;
  for(i=0;i<=PTR_STARS_NUM;i++) {
    tmpc->type=HTT_CLASS;
    tmpc->raw_type=RT_PTR;
    tmpc->size=sizeof(U8 *);
    tmpc->ptr_stars_cnt=i;
    tmpc++;
  }
  res->last_in_member_lst=&res->member_lst_and_root;
  res->size=0;
}
U0 PrsFunInit(CHashFun *res)
{
  I64 i;
  CHashFun *tmpf=res;
  for(i=0;i<=PTR_STARS_NUM;i++) {
    tmpf->type=HTT_FUN;
    tmpf->raw_type=RT_PTR;
    tmpf->size=sizeof(U8 *);
    tmpf->ptr_stars_cnt=i;
    tmpf++;
  }
  res->last_in_member_lst=&res->member_lst_and_root;
  res->size=0;
}
