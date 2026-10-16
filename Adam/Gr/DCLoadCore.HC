public CDC *DCLoad(U8 *src,I64 *_size=NULL,CTask *task=NULL)
{//Loads device context from mem.
  CDC *res;
  U8 *ptr=src;
  CArcCompress *arc;
  I64 body_size;
  if (!task) task=Fs;
  res=CAlloc(sizeof(CDC),task);
  res->win_task=task;
  res->mem_task=task;
  MemCpy(&res->start,ptr,offset(CDC.end)-offset(CDC.start));
  ptr+=offset(CDC.end)-offset(CDC.start);

  if (res->flags&DCF_PALETTE) {
    MemCpy(&res->palette,ptr,COLORS_NUM*sizeof(CBGR48));
    ptr+=COLORS_NUM*sizeof(CBGR48);
  } else
    MemCpy(&res->palette,gr_palette_std,COLORS_NUM*sizeof(CBGR48));

  body_size=res->width_internal*res->height;
  if (res->flags&DCF_COMPRESSED) {
    res->flags&=~DCF_COMPRESSED;
    arc=ptr;
    res->body=ExpandBuf(arc,task);
    ptr+=arc->compressed_size;
  } else {
    res->body=MAlloc(body_size,task);
    MemCpy(res->body,ptr,body_size);
    ptr+=body_size;
  }
  res->thick=1;
  res->r=Mat4x4IdentNew(task);
  res->r_norm.u32[1]=1;
  res->dc_signature=DCS_SIGNATURE_VAL;
  if (_size) *_size=ptr-src;
  return res;
}
