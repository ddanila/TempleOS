#ifndef CMP_BUF_IMPL
#define CMP_BUF_IMPL CmpBuf
#endif
CAOT *CMP_BUF_IMPL(U8 *buf,U8 *map_name=NULL,
  I64 *error_cnt=NULL, I64 *warning_cnt=NULL,U8 mapfile_drv_let=0)
{
  CCmpCtrl *cc;
  CAOT *res=NULL;
  cc=CmpCtrlNew(buf,CCF_DONT_FREE_BUF);
  cc->flags|=CCF_AOT_COMPILE;
  QueIns(cc,Fs->last_cc);
  res=CmpJoin(cc,CMPF_LEX_FIRST,map_name,mapfile_drv_let);
  if (error_cnt)   *error_cnt=cc->error_cnt;
  if (warning_cnt) *warning_cnt=cc->warning_cnt;
  QueRem(cc);
  CmpCtrlDel(cc);
  return res;
}
