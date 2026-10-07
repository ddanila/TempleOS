#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original graphics text operations, with corrected left glyph alignment.
public I64 GrPutChar(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,U8 ch)
{//2D. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  U8 reg *src,reg *dst,*font_ptr;
  I64 i,m,leading_pixels,trailing_pixels,leading_pixel_mask,trailing_pixel_mask,
	j,k1,kk1,w1,h1,w2,h2,reg bit_shift,reg color_mask,dist;
  CColorROPU32 color,c;
  CTask *win_task;

  if (dc->flags & DCF_SCRN_BITMAP) {
    win_task=dc->win_task;
    x+=win_task->scroll_x;
    y+=win_task->scroll_y;
  }

  if (x<0)
    w1=-x;
  else
    w1=0;
  if (y<0)
    h1=-y;
  else
    h1=0;
  w2=FONT_WIDTH;
  h2=FONT_HEIGHT;

  if (dc->flags & DCF_SCRN_BITMAP) {
    x+=win_task->pix_left;
    y+=win_task->pix_top;
  }
  if (dc->flags & DCF_LOCATE_NEAREST) {
    dist=DistSqrI64(x+w2>>1,y+h2>>1,dc->cur_x,dc->cur_y);
    if (dist<=dc->nearest_dist)
      dc->nearest_dist=dist;
  }
  if (dc->flags & DCF_SCRN_BITMAP) {
    if (x+w1<0) w1=-x;
    if (x+w2>win_task->pix_right+1)
      w2=win_task->pix_right+1-x;

    if (y+h1<0) h1=-y;
    if (y+h2>win_task->pix_bottom+1)
      h2=win_task->pix_bottom+1-y;
  }
  if (x+w2>dc->width)
    w2=dc->width-x;
  if (y+h2>dc->height)
    h2=dc->height-y;
  if (w1<w2<=FONT_WIDTH && h1<h2<=FONT_HEIGHT) {
    if (dc->flags & DCF_RECORD_EXTENTS) {
      if (x+w1	<dc->min_x) dc->min_x=x+w1;
      if (x+w2-1>dc->max_x) dc->max_x=x+w2-1;
      if (y+h1	<dc->min_y) dc->min_y=y+h1;
      if (y+h2-1>dc->max_y) dc->max_y=y+h2-1;
    }
    if (dc->flags & DCF_DONT_DRAW)
      return 1;
    color=dc->color;
    leading_pixels=-(w1+x)&7;
    if (!leading_pixels) leading_pixels=8;
    leading_pixel_mask=gr.to_8_bits[0xFF>>leading_pixels];
    bit_shift=-x&7;
    trailing_pixels=(x+w2)&7;
    trailing_pixel_mask=gr.to_8_bits[0xFF<<trailing_pixels&0xFF];
    if (leading_pixels+trailing_pixels>w2-w1) {
      leading_pixel_mask|=trailing_pixel_mask;
      trailing_pixels=0;
    }
    font_ptr=&text.font(U8 *)[FONT_HEIGHT*ch+h1];
    if (color.c0.rop==ROPB_COLLISION) {
      m=w1&(FONT_WIDTH-1);
#assert FONT_WIDTH==8
      color =dc->bkcolor.c0.color;
      for (i=w1;i<w2;i++,m++) {
	k1=(h1+y)*dc->width_internal+x;
	src=font_ptr;
	for (j=h2-h1;j;j--) {
	  c=dc->body[k1+i];
	  if (c!=TRANSPARENT && c!=color && Bt(src,m))
	    dc->collision_cnt++;
	  k1+=dc->width_internal;
	  src++;
	}
      }
    } else {
      color_mask=gr.to_8_colors[color.c0.color];
      k1=x+w1;
      kk1=(h1+y)*dc->width_internal+k1;
      if (!(dc->flags & DCF_SCRN_BITMAP) || dc->flags&DCF_ON_TOP) {
	if (leading_pixels) {
	  dst=dc->body+kk1&~7;
	  src=font_ptr;
	  //Use the previous byte only when this destination word starts before the glyph.
	  if (bit_shift && ((x+w1)&~7)<x)
	    src--;
	  switch [color.c0.rop] {
	    case ROPB_EQU:
	    case ROPB_MONO:
	      for (j=h2-h1;j;j--) {
		m=gr.to_8_bits[*src(U16 *)>>bit_shift&0xFF];
		*dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
		      (color_mask&m|*dst(I64 *)&~m)&~leading_pixel_mask;
		src++;
		dst+=dc->width_internal;
	      }
	      break;
	    case ROPB_XOR:
	      if (color_mask) {
		for (j=h2-h1;j;j--) {
		  *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			(*dst(I64 *)^gr.to_8_bits[*src(U16 *)>>bit_shift&0xFF])&
			~leading_pixel_mask;
		  src++;
		  dst+=dc->width_internal;
		}
	      }
	      break;
	  }
	  kk1+=8;
	}
	if (trailing_pixels) {
	  dst=dc->body+kk1&~7;
	  src=font_ptr+1;
	  if (bit_shift)
	    src--;
	  switch [color.c0.rop] {
	    case ROPB_EQU:
	    case ROPB_MONO:
	      for (j=h2-h1;j;j--) {
		m=gr.to_8_bits[*src(U16 *)>>bit_shift&0xFF];
		*dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
		      (color_mask&m|*dst(I64 *)&~m)&~trailing_pixel_mask;
		src++;
		dst+=dc->width_internal;
	      }
	      break;
	    case ROPB_XOR:
	      if (color_mask)
		for (j=h2-h1;j;j--) {
		  *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			(*dst(I64 *)^gr.to_8_bits[*src(U16 *)>>bit_shift&0xFF])&
			~trailing_pixel_mask;
		  src++;
		  dst+=dc->width_internal;
		}
	      break;
	  }
	}
      } else {
	if (leading_pixels) {
	  dst=dc->body+kk1&~7;
	  src=font_ptr;
	  //Use the previous byte only when this destination word starts before the glyph.
	  if (bit_shift && ((x+w1)&~7)<x)
	    src--;
	  switch [color.c0.rop] {
	    case ROPB_EQU:
	    case ROPB_MONO:
	      for (j=h1;j<h2;j++) {
		if (!IsPixCovered0(win_task,k1,y+j)) {
		  m=gr.to_8_bits[*src(U16 *)>>bit_shift&0xFF];
		  *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			(color_mask&m|*dst(I64 *)&~m)&~leading_pixel_mask;
		}
		src++;
		dst+=dc->width_internal;
	      }
	      break;
	    case ROPB_XOR:
	      if (color_mask)
		for (j=h1;j<h2;j++) {
		  if (!IsPixCovered0(win_task,k1,y+j))
		    *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			  (*dst(I64 *)^gr.to_8_bits
			  [*src(U16 *)>>bit_shift&0xFF])&
			  ~leading_pixel_mask;
		  src++;
		  dst+=dc->width_internal;
		}
	      break;
	  }
	  k1+=8;
	  kk1+=8;
	}
	if (trailing_pixels) {
	  dst=dc->body+kk1&~7;
	  src=font_ptr+1;
	  if (bit_shift)
	    src--;
	  switch [color.c0.rop] {
	    case ROPB_EQU:
	    case ROPB_MONO:
	      for (j=h1;j<h2;j++) {
		if (!IsPixCovered0(win_task,k1,y+j)) {
		  m=gr.to_8_bits[*src(U16 *)>>bit_shift&0xFF];
		  *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			(color_mask&m|*dst(I64 *)&~m)&~trailing_pixel_mask;
		}
		src++;
		dst+=dc->width_internal;
	      }
	      break;
	    case ROPB_XOR:
	      if (color_mask)
		for (j=h1;j<h2;j++) {
		  if (!IsPixCovered0(win_task,k1,y+j))
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  (*dst(I64 *)^gr.to_8_bits
			  [*src(U16 *)>>bit_shift&0xFF])&
			  ~trailing_pixel_mask;
		  src++;
		  dst+=dc->width_internal;
		}
	      break;
	  }
	}
      }
    }
    return 1;
  } else
    return 0;
}

I64 GrPutS(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,U8 *_s)
{//Use $LK,"GrPrint",A="MN:GrPrint"$()
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 x0,sx=0,sy=0,res;
  if (!_s) return 0;
  x0=x;
  res=0;
  while (*_s) {
    if (*_s=='\n') {
      x=x0;
      y+=FONT_HEIGHT;
      _s++;
    } else if (*_s=='\t') {
      x=x0+CeilU64(x-x0+FONT_WIDTH,8*FONT_WIDTH);
      _s++;
    } else if (*_s(U32 *)=='$$SY,') {
      if (_s[4]=='-') {
	_s++;
	sy='0'-_s[4];
      } else
	sy=_s[4]-'0';
      _s+=6;
    } else if (*_s(U32 *)=='$$SX,') {
      if (_s[4]=='-') {
	_s++;
	sx='0'-_s[4];
      } else
	sx=_s[4]-'0';
      _s+=6;
    } else {
      res+=GrPutChar(dc,x+sx,y+sy,*_s);
      x+=FONT_WIDTH;
      _s++;
    }
  }
  return res;
}

I64 GrVPutS(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,U8 *_s)
{//Vertical Text.  Use $LK,"GrVPrint",A="MN:GrVPrint"$()
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 y0,sx=0,sy=0,res;
  U8 buf[2];
  if (!_s) return 0;
  y0=y;
  res=0;
  buf[1]=0;
  while (*_s) {
    if (*_s=='\n') {
      y=y0;
      x+=FONT_WIDTH;
      _s++;
    } else if (*_s=='\t') {
      y=y0+CeilU64(y-y0+FONT_HEIGHT,8*FONT_HEIGHT);
      _s++;
    } else if (*_s(U32 *)=='$$SY,') {
      if (_s[4]=='-') {
	_s++;
	sx='0'-_s[4];
      } else
	sx=_s[4]-'0';
      _s+=6;
    } else if (*_s(U32 *)=='$$SX,') {
      if (_s[4]=='-') {
	_s++;
	sy='0'-_s[4];
      } else
	sy=_s[4]-'0';
      _s+=6;
    } else {
      *buf=*_s++;
      res+=GrPutS(dc,x,y,buf);
      y+=FONT_HEIGHT;
    }
  }
  return res;
}

public I64 GrPrint(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,U8 *fmt,...)
{//2D. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 res;
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  res=GrPutS(dc,x,y,buf);
  Free(buf);
  return res;
}

public I64 GrVPrint(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,U8 *fmt,...)
{//2D. Vertical text. Clipping but not transformation.
  GRAPHICS_RESOLVE_DEFAULT_DC
  I64 res;
  U8 *buf=StrPrintJoin(NULL,fmt,argc,argv);
  res=GrVPutS(dc,x,y,buf);
  Free(buf);
  return res;
}

