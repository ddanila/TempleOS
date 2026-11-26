public U0 SpriteExtents(U8 *elems,I64 *min_x=NULL,I64 *max_x=NULL,
				   I64 *min_y=NULL,I64 *max_y=NULL)
{//Ignores flood fills.
  CDC *dc=DCNew(I32_MAX,I32_MAX,Fs,TRUE);
  DCExtentsInit(dc);
  Sprite3(dc,I32_MAX/2,I32_MAX/2,I32_MAX/2,elems);
  if (dc->min_x<=dc->max_x) {
    dc->min_x-=I32_MAX/2;
    dc->max_x-=I32_MAX/2;
  }
  if (dc->min_y<=dc->max_y) {
    dc->min_y-=I32_MAX/2;
    dc->max_y-=I32_MAX/2;
  }
  if (min_x) *min_x=dc->min_x;
  if (max_x) *max_x=dc->max_x;
  if (min_y) *min_y=dc->min_y;
  if (max_y) *max_y=dc->max_y;
  DCDel(dc);
}
