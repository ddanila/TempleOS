public U8 *DCSave(CDC *dc,I64 *_size=NULL,I64 dcsf_flags=DCSF_COMPRESSED)
{//Stores device context to mem, perhaps, with compression.
  U8 *res,*ptr,*body;
  CArcCompress *arc;
  I64 body_size=dc->width_internal*dc->height,total_size,flags;
  CBGR48 palette[COLORS_NUM];

  if (dcsf_flags&DCSF_COMPRESSED) {
    arc=CompressBuf(dc->body,body_size);
    body_size=arc->compressed_size;
    body=arc;
  } else {
    arc=NULL;
    body=dc->body;
  }

  total_size=offset(CDC.end)-offset(CDC.start)+body_size;
  if (dcsf_flags&DCSF_COMPRESSED)
    flags=DCF_COMPRESSED;
  else
    flags=0;

  if (dcsf_flags&DCSF_PALETTE_GET)
    GrPaletteGet(palette);
  else
    MemCpy(palette,&dc->palette,COLORS_NUM*sizeof(CBGR48));
  if (MemCmp(palette,gr_palette_std,COLORS_NUM*sizeof(CBGR48))) {
    flags|=DCF_PALETTE;
    total_size+=COLORS_NUM*sizeof(CBGR48);
  }

  ptr=res=MAlloc(total_size);

#assert !offset(CDC.start)
  MemCpy(ptr,&dc->start,offset(CDC.end)-offset(CDC.start));
  ptr(CDC *)->flags=flags;
  ptr+=offset(CDC.end)-offset(CDC.start);

#assert offset(CDC.end)==offset(CDC.palette)
  if (flags&DCF_PALETTE) {
    MemCpy(ptr,palette,COLORS_NUM*sizeof(CBGR48));
    ptr+=COLORS_NUM*sizeof(CBGR48);
  }

  MemCpy(ptr,body,body_size);
  ptr+=body_size;

  Free(arc);
  if (_size) *_size=total_size;
  return res;
}

