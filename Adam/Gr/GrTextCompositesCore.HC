#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original text box and diamond rendering.
public Bool GrTextBox3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x1,I64 y1,I64 z1,U8 *s,I64 border=2)
{//3D. Transformation. DCF_SYMMETRY is silly.
  GRAPHICS_RESOLVE_DEFAULT_DC
  U8 *ptr;
  I64 ch,res,w,w_max,h;
  if (!s) return FALSE;
  ptr=s;
  w=0;	w_max=0; h=FONT_HEIGHT;

  if (dc->flags & DCF_TRANSFORMATION)
    (*dc->transform)(dc,&x1,&y1,&z1);
  while (ch=*ptr++) {
    if (ch=='\t')
      w=CeilU64(w+FONT_WIDTH,FONT_WIDTH*8);
    else if (ch=='\n') {
      if (w>w_max) w_max=w;
      w=0;
      h+=FONT_HEIGHT;
    } else
      w+=FONT_WIDTH;
  }
  if (w>w_max) w_max=w;
  res=GrPrint(dc,x1,y1,"%s",s);
  res|=GrLine(dc,x1-border	   ,y1-border  ,x1+w_max+border,y1-border);
  res|=GrLine(dc,x1-border	   ,y1+h+border,x1+w_max+border,y1+h+border);
  res|=GrLine(dc,x1-border	   ,y1-border  ,x1-border,y1+h+border);
  res|=GrLine(dc,x1+w_max+border,y1-border  ,x1+w_max+border,y1+h+border);
  return ToBool(res);
}

#define DIAMOND_SLOPE_MAX	2.75

public Bool GrTextDiamond3(CDC *dc=GRAPHICS_DEFAULT_DC,
	I64 x1,I64 y1,I64 z1,U8 *_s,I64 border=2)
{//3D. Transformation. DCF_SYMMETRY is silly.
  GRAPHICS_RESOLVE_DEFAULT_DC
  Bool first=TRUE;
  U8 ch,*ptr,*ptr_end,*st,*s;
  I64 res=0,y,dx,dy,dx_old,dy_old,w,h=FONT_HEIGHT;
  F64 m;
  if (!_s) return FALSE;
  if (dc->flags & DCF_TRANSFORMATION)
    (*dc->transform)(dc,&x1,&y1,&z1);

  ptr=s=StrNew(_s);
  while (ch=*ptr) {
    if (ch=='\r'||ch=='\t')
      *ptr=CH_SPACE;
    if (ch=='\n') {
      *ptr=0;
      h+=FONT_HEIGHT;
    }
    ptr++;
  }
  ptr_end=ptr+1;

  y=y1-h>>1;
  dx=FONT_WIDTH +border;      //Minimum
  dy=FONT_HEIGHT+border+h>>1; //Minimum
  ptr=s;
  while (ptr!=ptr_end) {
    st=ptr;
    while (*ptr++);
    StrUtil(st,SUF_REM_LEADING|SUF_REM_TRAILING);

    w=(StrLen(st)*FONT_WIDTH)>>1;
    if (first) {
      res|=GrPrint(dc,x1-w,y,"%s",st);
      first=FALSE;
    } else
      res|=GrPrint(dc,x1-w,y,"%s",st);
    if (w) {
      w+=border;
      do {
	dx_old=dx; dy_old=dy;
	m=ToF64(dx)/dy;
	if (m<1/DIAMOND_SLOPE_MAX) {
	  dy=MaxI64(dy,Ceil(DIAMOND_SLOPE_MAX*dx));
	  m=1/DIAMOND_SLOPE_MAX;
	} else if (m>DIAMOND_SLOPE_MAX) {
	  dy=MaxI64(dy,Ceil(dx/DIAMOND_SLOPE_MAX));
	  m=DIAMOND_SLOPE_MAX;
	}
	dx=MaxI64(dx,w+Ceil(m*AbsI64(y-y1)));
	dx=MaxI64(dx,w+Ceil(m*AbsI64(y+FONT_HEIGHT-y1)));
      } while (dx!=dx_old || dy!=dy_old);
    }
    y+=FONT_HEIGHT;
  }
  Free(s);

  res|=GrLine(dc,x1,y1-dy,x1+dx,y1);
  res|=GrLine(dc,x1+dx,y1,x1,y1+dy);
  res|=GrLine(dc,x1,y1+dy,x1-dx,y1);
  res|=GrLine(dc,x1-dx,y1,x1,y1-dy);
  return ToBool(res);
}

