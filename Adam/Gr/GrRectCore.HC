#ifdef I386_GR_RECT_EXPLICIT_CONTEXT
public I64 GrRect(CDC *dc,I64 x,I64 y,I64 w,I64 h)
#else
public I64 GrRect(CDC *dc=gr.dc,I64 x,I64 y,I64 w,I64 h)
#endif
{//2D. Width Height. Clipping but not transformation.
//Returns cnt of pixs changed.
  I64 i,res=0,j,k1,kk1,w1,h1,w2,h2,dist,
	leading_pixels,original_leading_pixels,whole_I64s,
	trailing_pixels,leading_pixel_mask,trailing_pixel_mask,
	win_z_buf_line_inc,win_z_buf_line_dec,win_z_num,color_mask;
  U8 reg *dst;
  U16 reg *win_z_buf_ptr;
  CColorROPU32 color,c,dither_colors;
  Bool dither,probability_dither;
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
  w2=w;
  h2=h;

  if (dc->flags & DCF_SCRN_BITMAP) {
    x+=win_task->pix_left;
    y+=win_task->pix_top;
  }
  if (dc->flags & DCF_LOCATE_NEAREST) {//TODO:Untested
    if (x<=dc->cur_x<=x+w && y<=dc->cur_y<=y+h)
      dist=0;
    else
      dist=DistSqrI64(x+w>>1,y+h>>1,dc->cur_x,dc->cur_y);
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
  if (w1<w2<=w && h1<h2<=h) {
    if (dc->flags & DCF_RECORD_EXTENTS) {
      if (x+w1	<dc->min_x) dc->min_x=x+w1;
      if (x+w2-1>dc->max_x) dc->max_x=x+w2-1;
      if (y+h1	<dc->min_y) dc->min_y=y+h1;
      if (y+h2-1>dc->max_y) dc->max_y=y+h2-1;
    }
    if (dc->flags & DCF_DONT_DRAW)
      return TRUE;
    color=dc->color;
    if (color.c1.rop&(ROPBF_DITHER|ROPBF_PROBABILITY_DITHER)) {
      dither=TRUE;
      if (color.c1.rop&ROPBF_PROBABILITY_DITHER) {
	probability_dither=TRUE;
	color.c1.rop=color.c0.rop;
	dither_colors=color;
      } else {
	probability_dither=FALSE;
	color.c1.rop=color.c0.rop;
      }
    } else
      dither=FALSE;
    original_leading_pixels=leading_pixels=-(w1+x)&7;
    leading_pixel_mask=gr.to_8_bits[0xFF>>leading_pixels];
    whole_I64s=(w2-w1-leading_pixels)>>3;
    if (whole_I64s<0) whole_I64s=0;
    trailing_pixels=(x+w2)&7;
    trailing_pixel_mask=gr.to_8_bits[0xFF<<trailing_pixels&0xFF];
    if (leading_pixels+trailing_pixels>w2-w1) {
      leading_pixel_mask|=trailing_pixel_mask;
      leading_pixels=w2-w1; //Correct so it's right for res.
      trailing_pixels=0;
    }
    if (color.c0.rop==ROPB_COLLISION) {//TODO: Might want to check win_z_buf
      color =dc->bkcolor.c0.color;
      k1=(h1+y)*dc->width_internal+x;
      res=-dc->collision_cnt;
      for (j=h2-h1;j;j--) {
	for (i=w1;i<w2;i++) {
	  c=dc->body[k1+i];
	  if (c!=TRANSPARENT && c!=color)
	    dc->collision_cnt++;
	}
	k1+=dc->width_internal;
      }
      res+=dc->collision_cnt;
    } else {
      if (!(dc->flags & DCF_SCRN_BITMAP) || dc->flags&DCF_ON_TOP)
	win_z_buf_ptr=NULL;
      else {
	win_z_num=win_task->win_z_num;
	win_z_buf_ptr=gr.win_z_buf(U8 *)+((h1+y)/FONT_HEIGHT*TEXT_COLS+
	      (w1+x)/FONT_WIDTH)*sizeof(U16);
	win_z_buf_line_dec=whole_I64s;
	if (leading_pixels)
	  win_z_buf_line_dec++;
	if (trailing_pixels)
	  win_z_buf_line_dec++;
	win_z_buf_line_dec*=sizeof(U16);
	win_z_buf_line_inc=TEXT_COLS*sizeof(U16)-win_z_buf_line_dec;
      }
      kk1=(h1+y)*dc->width_internal+x+w1;
      if (dither) {
	if (probability_dither) {
	  if (RandU16<dc->dither_probability_u16)
	    color.c0=dither_colors.c1;
	  else
	    color.c0=dither_colors.c0;
	  switch [color.c0.rop] {
	    case ROPB_EQU:
	    case ROPB_MONO:
	      if (win_z_buf_ptr) {
		res=0;
		for (j=h1;j<h2;j++) {
		  color_mask=gr.to_8_colors[color.c0.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels) {
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			    color_mask&~leading_pixel_mask;
		      res+=leading_pixels;
		    }
		    dst(I64 *)++;
		  }
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)=color_mask;
		      res+=8;
		    }
		  if (trailing_pixels && win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  color_mask&~trailing_pixel_mask;
		    res+=trailing_pixels;
		  }
		  if ((j+y)&7==7)
		    win_z_buf_ptr(U8 *)+=win_z_buf_line_inc;
		  else
		    win_z_buf_ptr(U8 *)-=win_z_buf_line_dec;
		  kk1+=dc->width_internal;
		  if (RandU16<dc->dither_probability_u16)
		    color.c0=dither_colors.c1;
		  else
		    color.c0=dither_colors.c0;
		}
	      } else {
		for (j=h2-h1;j;j--) {
		  color_mask=gr.to_8_colors[color.c0.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels)
		    *dst(I64 *)++=*dst(I64 *)&leading_pixel_mask|
			  color_mask&~leading_pixel_mask;
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    *dst(I64 *)=color_mask;
		  if (trailing_pixels)
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  color_mask&~trailing_pixel_mask;
		  kk1+=dc->width_internal;
		  if (RandU16<dc->dither_probability_u16)
		    color.c0=dither_colors.c1;
		  else
		    color.c0=dither_colors.c0;
		}
		res=(h2-h1)*(w2-w1);
	      }
	      break;
	    case ROPB_XOR:
	      if (win_z_buf_ptr) {
		res=0;
		for (j=h1;j<h2;j++) {
		  color_mask=gr.to_8_colors[color.c0.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels) {
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			    *dst(I64 *)^color_mask&~leading_pixel_mask;
		      res+=leading_pixels;
		    }
		    dst(I64 *)++;
		  }
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)^=color_mask;
		      res+=8;
		    }
		  if (trailing_pixels && win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  *dst(I64 *)^color_mask&~trailing_pixel_mask;
		    res+=trailing_pixels;
		  }
		  if ((j+y)&7==7)
		    win_z_buf_ptr(U8 *)+=win_z_buf_line_inc;
		  else
		    win_z_buf_ptr(U8 *)-=win_z_buf_line_dec;
		  kk1+=dc->width_internal;
		  if (RandU16<dc->dither_probability_u16)
		    color.c0=dither_colors.c1;
		  else
		    color.c0=dither_colors.c0;
		}
	      } else {
		for (j=h2-h1;j;j--) {
		  color_mask=gr.to_8_colors[color.c0.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels)
		    *dst(I64 *)++=*dst(I64 *)&leading_pixel_mask|
			  *dst(I64 *)^color_mask&~leading_pixel_mask;
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    *dst(I64 *)^=color_mask;
		  if (trailing_pixels)
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  *dst(I64 *)^color_mask&~trailing_pixel_mask;
		  kk1+=dc->width_internal;
		  if (RandU16<dc->dither_probability_u16)
		    color.c0=dither_colors.c1;
		  else
		    color.c0=dither_colors.c0;
		}
		res=(h2-h1)*(w2-w1);
	      }
	      break;
	  }
	} else {
	  if (((x+w1-original_leading_pixels)^(y+h1))&1)
	    SwapU16(&color.c0,&color.c1);
	  switch [color.c0.rop] {
	    case ROPB_EQU:
	    case ROPB_MONO:
	      if (win_z_buf_ptr) {
		res=0;
		for (j=h1;j<h2;j++) {
		  color_mask=gr.to_8_bits[0x55]&gr.to_8_colors[color.c0.color]|
			gr.to_8_bits[0xAA]&gr.to_8_colors[color.c1.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels) {
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			    color_mask&~leading_pixel_mask;
		      res+=leading_pixels;
		    }
		    dst(I64 *)++;
		  }
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)=color_mask;
		      res+=8;
		    }
		  if (trailing_pixels && win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  color_mask&~trailing_pixel_mask;
		    res+=trailing_pixels;
		  }
		  if ((j+y)&7==7)
		    win_z_buf_ptr(U8 *)+=win_z_buf_line_inc;
		  else
		    win_z_buf_ptr(U8 *)-=win_z_buf_line_dec;
		  kk1+=dc->width_internal;
		  SwapU16(&color.c0,&color.c1);
		}
	      } else {
		for (j=h2-h1;j;j--) {
		  color_mask=gr.to_8_bits[0x55]&gr.to_8_colors[color.c0.color]|
			gr.to_8_bits[0xAA]&gr.to_8_colors[color.c1.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels)
		    *dst(I64 *)++=*dst(I64 *)&leading_pixel_mask|
			  color_mask&~leading_pixel_mask;
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    *dst(I64 *)=color_mask;
		  if (trailing_pixels)
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  color_mask&~trailing_pixel_mask;
		  kk1+=dc->width_internal;
		  SwapU16(&color.c0,&color.c1);
		}
		res=(h2-h1)*(w2-w1);
	      }
	      break;
	    case ROPB_XOR:
	      if (win_z_buf_ptr) {
		res=0;
		for (j=h1;j<h2;j++) {
		  color_mask=gr.to_8_bits[0x55]&gr.to_8_colors[color.c0.color]|
			gr.to_8_bits[0xAA]&gr.to_8_colors[color.c1.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels) {
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			    *dst(I64 *)^color_mask&~leading_pixel_mask;
		      res+=leading_pixels;
		    }
		    dst(I64 *)++;
		  }
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    if (win_z_num>=*win_z_buf_ptr++) {
		      *dst(I64 *)^=color_mask;
		      res+=8;
		    }
		  if (trailing_pixels && win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  *dst(I64 *)^color_mask&~trailing_pixel_mask;
		    res+=trailing_pixels;
		  }
		  if ((j+y)&7==7)
		    win_z_buf_ptr(U8 *)+=win_z_buf_line_inc;
		  else
		    win_z_buf_ptr(U8 *)-=win_z_buf_line_dec;
		  kk1+=dc->width_internal;
		  SwapU16(&color.c0,&color.c1);
		}
	      } else {
		for (j=h2-h1;j;j--) {
		  color_mask=gr.to_8_bits[0x55]&gr.to_8_colors[color.c0.color]|
			gr.to_8_bits[0xAA]&gr.to_8_colors[color.c1.color];
		  dst=dc->body+kk1&~7;
		  if (leading_pixels)
		    *dst(I64 *)++=*dst(I64 *)&leading_pixel_mask|
			  *dst(I64 *)^color_mask&~leading_pixel_mask;
		  for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		    *dst(I64 *)^=color_mask;
		  if (trailing_pixels)
		    *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			  *dst(I64 *)^color_mask&~trailing_pixel_mask;
		  kk1+=dc->width_internal;
		  SwapU16(&color.c0,&color.c1);
		}
		res=(h2-h1)*(w2-w1);
	      }
	      break;
	  }
	}
      } else {
	color_mask=gr.to_8_colors[color.c0.color];
	switch [color.c0.rop] {
	  case ROPB_EQU:
	  case ROPB_MONO:
	    if (win_z_buf_ptr) {
	      res=0;
	      for (j=h1;j<h2;j++) {
		dst=dc->body+kk1&~7;
		if (leading_pixels) {
		  if (win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			  color_mask&~leading_pixel_mask;
		    res+=leading_pixels;
		  }
		  dst(I64 *)++;
		}
		for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		  if (win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)=color_mask;
		    res+=8;
		  }
		if (trailing_pixels && win_z_num>=*win_z_buf_ptr++) {
		  *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			color_mask&~trailing_pixel_mask;
		  res+=trailing_pixels;
		}
		if ((j+y)&7==7)
		  win_z_buf_ptr(U8 *)+=win_z_buf_line_inc;
		else
		  win_z_buf_ptr(U8 *)-=win_z_buf_line_dec;
		kk1+=dc->width_internal;
	      }
	    } else {
	      for (j=h2-h1;j;j--) {
		dst(I64 *)=dc->body+kk1&~7;
		if (leading_pixels)
		  *dst(I64 *)++=*dst(I64 *)&leading_pixel_mask|
			color_mask&~leading_pixel_mask;
		for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		  *dst(I64 *)=color_mask;
		if (trailing_pixels)
		  *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			color_mask&~trailing_pixel_mask;
		kk1+=dc->width_internal;
	      }
	      res=(h2-h1)*(w2-w1);
	    }
	    break;
	  case ROPB_XOR:
	    if (win_z_buf_ptr) {
	      res=0;
	      for (j=h1;j<h2;j++) {
		dst=dc->body+kk1&~7;
		if (leading_pixels) {
		  if (win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)=*dst(I64 *)&leading_pixel_mask|
			  *dst(I64 *)^color_mask&~leading_pixel_mask;
		    res+=leading_pixels;
		  }
		  dst(I64 *)++;
		}
		for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		  if (win_z_num>=*win_z_buf_ptr++) {
		    *dst(I64 *)^=color_mask;
		    res+=8;
		  }
		if (trailing_pixels && win_z_num>=*win_z_buf_ptr++) {
		  *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			*dst(I64 *)^color_mask&~trailing_pixel_mask;
		  res+=trailing_pixels;
		}
		if ((j+y)&7==7)
		  win_z_buf_ptr(U8 *)+=win_z_buf_line_inc;
		else
		  win_z_buf_ptr(U8 *)-=win_z_buf_line_dec;
		kk1+=dc->width_internal;
	      }
	    } else {
	      for (j=h2-h1;j;j--) {
		dst=dc->body+kk1&~7;
		if (leading_pixels)
		  *dst(I64 *)++=*dst(I64 *)&leading_pixel_mask|
			*dst(I64 *)^color_mask&~leading_pixel_mask;
		for (i=0;i<whole_I64s;i++,dst(I64 *)++)
		  *dst(I64 *)^=color_mask;
		if (trailing_pixels)
		  *dst(I64 *)=*dst(I64 *)&trailing_pixel_mask|
			*dst(I64 *)^color_mask&~trailing_pixel_mask;
		kk1+=dc->width_internal;
	      }
	      res=(h2-h1)*(w2-w1);
	    }
	    break;
	}
      }
    }
  }
  return res;
}

