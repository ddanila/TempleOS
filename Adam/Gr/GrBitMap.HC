#help_index "Graphics"

Option(OPTf_WARN_HEADER_MISMATCH,OFF);
#include "/Adam/Gr/GrPixelCore.HC"
Option(OPTf_WARN_HEADER_MISMATCH,ON);

#help_index "Graphics;Graphics/Device Contexts"

#include "/Adam/Gr/GrBlotCore.HC"

#help_index "Graphics/Device Contexts"

U8 *GrBitMap4ToBitMap8(U8 *dst,U8 *src,I64 src_size,I64 bkcolor)
{
  I64 c,k,i=src_size*2,i1=i>>3;
  for (k=0;k<i;k++) {
    c=0;
    if (Bt(src	   ,k)) c|=1;
    if (Bt(src+i1  ,k)) c|=2;
    if (Bt(src+i1*2,k)) c|=4;
    if (Bt(src+i1*3,k)) c|=8;
    if (c==bkcolor) c=TRANSPARENT;
    *dst++=c;
  }
  return dst;
}

U8 *GrBitMap1ToBitMap8(U8 *dst,U8 *src,I64 src_size,I64 bkcolor)
{
  I64 c,k,i=src_size*8;
  for (k=0;k<i;k++) {
    c=0;
    if (Bt(src,k))  c=COLOR_MONO;
    if (c==bkcolor) c=TRANSPARENT;
    *dst++=c;
  }
  return dst;
}

#include "/Adam/Gr/DCDiffCore.HC"

#help_index "Graphics/Char;Char/Graphics"

#include "/Adam/Gr/GrTextCore.HC"

#help_index "Graphics"
#include "/Adam/Gr/GrRectCore.HC"

#include "/Adam/Gr/GrFloodRayCore.HC"

#include "/Adam/Gr/GrRasterSpanCore.HC"
