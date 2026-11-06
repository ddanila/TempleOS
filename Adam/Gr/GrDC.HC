#include "/Adam/Gr/GrDCCore.HC"

#include "/Adam/Gr/DCCopyCore.HC"

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

#include "/Adam/Gr/DCSaveCore.HC"

#include "/Adam/Gr/DCLoadCore.HC"

#help_index "Graphics/GR Files"
#help_file "::/Doc/GRFiles"
#help_index "Graphics/Device Contexts;Graphics/GR Files"

#define GR_FILE_MAX	(offset(CDC.end)-offset(CDC.start)+\
	COLORS_NUM*sizeof(CBGR48)+sizeof(CArcCtrl)+GR_WIDTH*GR_HEIGHT)

#include "/Adam/Gr/GRWriteCore.HC"

#include "/Adam/Gr/GRReadCore.HC"

#help_index "Graphics/Sprite;Graphics/GR Files;DolDoc/Output;StdOut/DolDoc"
#include "/Adam/Gr/DocGRCore.HC"

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
