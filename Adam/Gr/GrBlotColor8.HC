U0 DCBlotColor8(CDC *dc,CDC *img)
{
  U8  *src=img->body,*b0=dc->body;
  I64 j,k,d0=img->width_internal*img->height;
  for (k=0;k<d0;k++) {
    j=*src++;
    if (j!=TRANSPARENT)
      *b0++=j;
    else
      b0++;
  }
}

