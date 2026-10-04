U0 FunSegCacheAdd(CHash *tmps,U8 *addr)
{
  I64 i;
  CDbgInfo *dbg_info;
  CFunSegCache *tmpfsc;
  if (tmps && tmps->type&HTT_FUN &&
	(dbg_info=tmps(CHashFun *)->dbg_info)) {
    lock i=dbg.fun_seg_cache_index++;
    tmpfsc=&dbg.fun_seg_cache[i&(FUN_SEG_CACHE_SIZE-1)];
    tmpfsc->base=dbg_info->body[0];
    if (addr<tmpfsc->base)
      tmpfsc->base=addr;
    tmpfsc->limit=dbg_info->body[dbg_info->max_line+1-dbg_info->min_line];
    if (addr>=tmpfsc->limit)
      tmpfsc->limit=addr+1;
    i=MinI64(StrLen(tmps->str),FUN_SEG_CACHE_STR_LEN-1);
    MemCpy(tmpfsc->str,tmps->str,i);
    tmpfsc->str[i]=0;
    tmpfsc->time_stamp=tS;
  }
}

U8 *FunSegCacheFind(U8 *addr,I64 *_offset)
{
  I64 i;
  F64 timeout;
  CFunSegCache *tmpfsc=dbg.fun_seg_cache;
  if (addr==SYS_IDLE_PT) {
    *_offset=0;
    return "SYS_IDLE_PT";
  } else {
    timeout=tS+8.0;
    for (i=0;i<FUN_SEG_CACHE_SIZE;i++,tmpfsc++)
      if (tmpfsc->base<=addr<tmpfsc->limit &&
	    tmpfsc->time_stamp>timeout) {
	*_offset=addr-tmpfsc->base;
	return tmpfsc->str;
      }
    return NULL;
  }
}

