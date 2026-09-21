#include "/Adam/Gr/GrDCCore.HC"

public CDC *DCCopy(CDC *dc,CTask *task=NULL)
{//Alloc copy of dc, including image body, rot mat and depth buf.
  CDC *res;
  if (!dc) return NULL;
  if (dc->dc_signature!=DCS_SIGNATURE_VAL)
    throw('Graphics');
  res=MAllocIdent(dc,task);
  DCMat4x4Set(res,Mat4x4New(dc->r,task));
  res->mem_task=task;
  res->body=MAllocIdent(dc->body,task);
  res->depth_buf=MAllocIdent(dc->depth_buf,task);
  return res;
}

public U0 DCMono(CDC *dc,
  I64 quest=TRANSPARENT,I64 true_color=0,I64 false_color=COLOR_MONO)
{//Set entire device context to one of two colors.
  I64 i;
  U8 *dst;
  dst=dc->body;
  i=dc->width_internal*dc->height;
  while (i--)
    if (*dst==quest)
      *dst++=true_color;
    else
      *dst++=false_color;
}

public I64 DCColorChg(CDC *dc,I64 src_color,I64 dst_color=TRANSPARENT)
{//Find and replace src color with dst in device context.
  I64 i,res=0;
  U8 *dst;
  dst=dc->body;
  i=dc->width_internal*dc->height;
  while (i--)
    if (*dst==src_color) {
      *dst++=dst_color;
      res++;
    } else
      dst++;
  return res;
}

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

#help_index "Graphics/GR Files"
#help_file "::/Doc/GRFiles"
#help_index "Graphics/Device Contexts;Graphics/GR Files"

#define GR_FILE_MAX	(offset(CDC.end)-offset(CDC.start)+\
	COLORS_NUM*sizeof(CBGR48)+sizeof(CArcCtrl)+GR_WIDTH*GR_HEIGHT)

public I64 GRWrite(U8 *filename,CDC *dc,I64 dcsf_flags=DCSF_COMPRESSED)
{//TempleOS GR File.
  I64	size;
  U8	*st=ExtDft(filename,"GR.Z"),
	*src=DCSave(dc,&size,dcsf_flags);
  FileWrite(st,src,size);
  Free(st);
  Free(src);
  return size;
}

public CDC *GRRead(U8 *filename,CTask *task=NULL)
{//TempleOS GR File.
  CDC	*dc=NULL;
  U8	*st=ExtDft(filename,"GR.Z"),
	*src=FileRead(st);
  if (src)
    dc=DCLoad(src,,task);
  Free(src);
  Free(st);
  return dc;
}

#help_index "Graphics/Sprite;Graphics/GR Files;DolDoc/Output;StdOut/DolDoc"
public U0 DocGR(CDoc *doc=NULL,U8 *filename)
{//Put a GR file into a document as asprite.
  CDC *dc=GRRead(filename);
  CSprite *elems=DC2Sprite(dc);
  DocSprite(doc,elems);
  Free(elems);
  DCDel(dc);
}

#help_index "Graphics/Device Contexts;Graphics/Scrn"
public CDC *DCScrnCapture(Bool include_zoom=TRUE,CTask *task=NULL)
{//Capture scrn to a device context.
  CDC *dc;
  U8 *dst;
  Refresh(0,FALSE);
  if (include_zoom)
    dc=DCCopy(gr.scrn_image,task);
  else
    dc=DCCopy(gr.dc1,task);
  dc->flags&=~DCF_SCRN_BITMAP;
  dst=MAlloc(dc->width_internal*dc->height,task);
//Pick background color that never occurs. COLOR_INVALID
  GrBitMap4ToBitMap8(dst,dc->body,
	(dc->width_internal*dc->height)>>1,COLOR_INVALID);
  Free(dc->body);
  dc->body=dst;
  return dc;
}
