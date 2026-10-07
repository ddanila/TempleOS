#include "/Adam/Gr/GrDefaultContext.HH"
//Complete original Sprite3 renderer, shared by the native port.
public U0 Sprite3(CDC *dc=GRAPHICS_DEFAULT_DC,I64 x,I64 y,I64 z,U8 *elems,
	Bool just_one_elem=FALSE)
{//Plot a sprite into a CDC.
  GRAPHICS_RESOLVE_DEFAULT_DC
  CSprite *tmpg=elems-offset(CSprite.start);
  I64 i,j,k,x1,y1,z1,x2,y2,
	*old_r,*r2,old_flags=dc->flags,old_pen_width=dc->thick;
  I32 *ptr;
  CColorROPU32 old_color=dc->color;
  CDC *img;
  CD3I32 *p,*p2;
  CGrSym old_sym;
  MemCpy(&old_sym,&dc->sym,sizeof(CGrSym));
  if (dc->flags & DCF_LOCATE_NEAREST)
    dc->nearest_dist=I64_MAX;
  while (tmpg->type&SPG_TYPE_MASK) {
    switch (tmpg->type&SPG_TYPE_MASK) {
      case SPT_COLOR:
	dc->color=dc->color&~(COLORROP_COLORS_MASK|ROPF_DITHER)|tmpg->c.color;
	break;
      case SPT_DITHER_COLOR:
	dc->color=dc->color&~COLORROP_COLORS_MASK|
	      tmpg->d.dither_color.u8[0]|
	      tmpg->d.dither_color.u8[1]<<COLORROP_BITS|ROPF_DITHER;
	break;
      case SPT_THICK:
	dc->thick=tmpg->t.thick;
	DCThickScale(dc);
	break;
      case SPT_TRANSFORM_ON:
	if (!(dc->flags&DCF_TRANSFORMATION)) {
	  x-=dc->x;
	  y-=dc->y;
	  z-=dc->z;
	}
	dc->flags|=DCF_TRANSFORMATION;
	break;
      case SPT_TRANSFORM_OFF:
	if (dc->flags&DCF_TRANSFORMATION) {
	  x+=dc->x;
	  y+=dc->y;
	  z+=dc->z;
	}
	dc->flags&=~DCF_TRANSFORMATION;
	break;
      case SPT_PT:
	GrPlot3(dc,tmpg->p.x1+x,tmpg->p.y1+y,z);
	break;
      case SPT_TEXT:
	GrPrint3(dc,tmpg->ps.x1+x,tmpg->ps.y1+y,z,"%s",tmpg->ps.st);
	break;
      case SPT_TEXT_BOX:
	GrTextBox3(dc,tmpg->ps.x1+x,tmpg->ps.y1+y,z,tmpg->ps.st);
	break;
      case SPT_TEXT_DIAMOND:
	GrTextDiamond3(dc,tmpg->ps.x1+x,tmpg->ps.y1+y,z,tmpg->ps.st);
	break;
      case SPT_FLOOD_FILL:
	GrFloodFill3(dc,tmpg->p.x1+x,tmpg->p.y1+y,z,FALSE);
	break;
      case SPT_FLOOD_FILL_NOT:
	i=dc->color;
	dc->color=dc->color.c0;
	GrFloodFill3(dc,tmpg->p.x1+x,tmpg->p.y1+y,z,TRUE);
	dc->color=i;
	break;
      case SPT_SHIFT:
	x+=tmpg->p.x1;
	y+=tmpg->p.y1;
	break;
      case SPT_LINE:
	GrLine3(dc,tmpg->pp.x1+x,tmpg->pp.y1+y,z,
	      tmpg->pp.x2+x,tmpg->pp.y2+y,z);
	break;
      case SPT_ARROW:
	GrArrow3(dc,tmpg->pp.x1+x,tmpg->pp.y1+y,z,
	      tmpg->pp.x2+x,tmpg->pp.y2+y,z);
	break;
      case SPT_PLANAR_SYMMETRY:
	if (DCSymmetry3Set(dc,tmpg->pp.x1+x,tmpg->pp.y1+y,z,
	      tmpg->pp.x2+x,tmpg->pp.y2+y,z,
	      tmpg->pp.x2+x,tmpg->pp.y2+y,z+1))
	  dc->flags|=DCF_SYMMETRY;
	else
	  dc->flags&=~DCF_SYMMETRY;
	break;
      case SPT_BITMAP:
	img=CAlloc(sizeof(CDC));
	img->width=tmpg->pwhu.width;
	img->width_internal=(tmpg->pwhu.width+7)&~7;
	img->height=tmpg->pwhu.height;
	img->body=&tmpg->pwhu.u;
	img->dc_signature=DCS_SIGNATURE_VAL;
	GrBlot3(dc,tmpg->pwhu.x1+x,tmpg->pwhu.y1+y,z,img);
	Free(img);
	break;
      case SPT_RECT:
	GrRect3(dc,tmpg->pp.x1+x,tmpg->pp.y1+y,z,
	      tmpg->pp.x2-tmpg->pp.x1,tmpg->pp.y2-tmpg->pp.y1);
	break;
      case SPT_ROTATED_RECT:
	x1=tmpg->ppa.x1+x;
	y1=tmpg->ppa.y1+y;
	z1=z;
	Mat4x4MulXYZ(dc->r,&x1,&y1,&z1);
	old_r=dc->r;
	dc->flags|=DCF_TRANSFORMATION;
	r2=Mat4x4IdentNew;
	Mat4x4RotZ(r2,-tmpg->ppa.angle);
	Mat4x4TranslationEqu(r2,x1,y1,z1);
	DCMat4x4Set(dc,Mat4x4MulMat4x4New(old_r,r2));
	GrRect3(dc,0,0,0,
	      tmpg->ppa.x2-tmpg->ppa.x1,tmpg->ppa.y2-tmpg->ppa.y1);
	Free(dc->r);
	Free(r2);
	DCMat4x4Set(dc,old_r);
	dc->flags=dc->flags&~DCF_TRANSFORMATION|old_flags;
	break;
      case SPT_CIRCLE:
	GrCircle3(dc,tmpg->pr.x1+x,tmpg->pr.y1+y,z,tmpg->pr.radius);
	break;
      case SPT_ELLIPSE:
	GrEllipse3(dc,tmpg->pwha.x1+x,tmpg->pwha.y1+y,z,tmpg->pwha.width,
	      tmpg->pwha.height,tmpg->pwha.angle);
	break;
      case SPT_POLYGON:
	GrRegPoly3(dc,tmpg->pwhas.x1+x,tmpg->pwhas.y1+y,z,tmpg->pwhas.width,
	      tmpg->pwhas.height,tmpg->pwhas.sides,tmpg->pwhas.angle);
	break;
      case SPT_POLYLINE:
	ptr=&tmpg->nu.u;
	x1=ptr[0];
	y1=ptr[1];
	for (i=1;i<tmpg->nu.num;i++) {
	  x2=ptr[i<<1];
	  y2=ptr[i<<1+1];
	  GrLine3(dc,x1+x,y1+y,z,x2+x,y2+y,z);
	  x1=x2;y1=y2;
	}
	break;
      case SPT_POLYPT:
	x1=tmpg->npu.x;
	y1=tmpg->npu.y;
	ptr=&tmpg->npu.u;
	k=tmpg->npu.num*3;
	GrPlot3(dc,x1+x,y1+y,z);
	for (i=0;i<k;i+=3) {
	  j=BFieldExtU32(ptr,i,3);
	  x1+=gr_x_offsets[j];
	  y1+=gr_y_offsets[j];
	  GrPlot3(dc,x1+x,y1+y,z);
	}
	break;
      start:
	p2=p=MAlloc(tmpg->nu.num*sizeof(CD3I32));
	MemCpy(p,&tmpg->nu.u,tmpg->nu.num*sizeof(CD3I32));
	for (i=0;i<tmpg->nu.num;i++,p2++) {
	  p2->x+=x;
	  p2->y+=y;
	  p2->z+=z;
	}
	case SPT_BSPLINE2:
	  Gr2BSpline3(dc,p,tmpg->nu.num,FALSE);
	  break;
	case SPT_BSPLINE3:
	  Gr3BSpline3(dc,p,tmpg->nu.num,FALSE);
	  break;
	case SPT_BSPLINE2_CLOSED:
	  Gr2BSpline3(dc,p,tmpg->nu.num,TRUE);
	  break;
	case SPT_BSPLINE3_CLOSED:
	  Gr3BSpline3(dc,p,tmpg->nu.num,TRUE);
	  break;
      end:
	Free(p);
	break;
      case SPT_MESH:
	p2=p=MAlloc(tmpg->mu.vertex_cnt*sizeof(CD3I32));
	MemCpy(p,&tmpg->mu.u,tmpg->mu.vertex_cnt*sizeof(CD3I32));
	for (i=0;i<tmpg->mu.vertex_cnt;i++,p2++) {
	  p2->x+=x;
	  p2->y+=y;
	  p2->z+=z;
	}
	Gr3Mesh(dc,tmpg->mu.vertex_cnt,p,tmpg->mu.tri_cnt,
	      (&tmpg->mu.u)(U8 *)+sizeof(CD3I32)*tmpg->mu.vertex_cnt);
	Free(p);
	break;
      case SPT_SHIFTABLE_MESH:
	if (dc->flags&DCF_TRANSFORMATION) {
	  dc->x+=tmpg->pmu.x;
	  dc->y+=tmpg->pmu.y;
	  dc->z+=tmpg->pmu.z;
	  x1=x;
	  y1=y;
	  z1=z;
	} else {
	  x1=tmpg->pmu.x+x;
	  y1=tmpg->pmu.y+y;
	  z1=tmpg->pmu.z+z;
	}
	p2=p=MAlloc(tmpg->pmu.vertex_cnt*sizeof(CD3I32));
	MemCpy(p,&tmpg->pmu.u,tmpg->pmu.vertex_cnt*sizeof(CD3I32));
	for (i=0;i<tmpg->pmu.vertex_cnt;i++,p2++) {
	  p2->x+=x1;
	  p2->y+=y1;
	  p2->z+=z1;
	}
	Gr3Mesh(dc,tmpg->pmu.vertex_cnt,p,tmpg->pmu.tri_cnt,
	      (&tmpg->pmu.u)(U8 *)+sizeof(CD3I32)*tmpg->pmu.vertex_cnt);
	Free(p);
	if (dc->flags&DCF_TRANSFORMATION) {
	  dc->x-=tmpg->pmu.x;
	  dc->y-=tmpg->pmu.y;
	  dc->z-=tmpg->pmu.z;
	}
	break;
    }
    if (just_one_elem) break;
    tmpg(U8 *)+=SpriteElemSize(tmpg);
  }
  MemCpy(&dc->sym,&old_sym,sizeof(CGrSym));
  dc->color=old_color;
  dc->thick=old_pen_width;
  dc->flags=dc->flags&~(DCF_SYMMETRY|DCF_TRANSFORMATION) |
	old_flags&(DCF_SYMMETRY|DCF_TRANSFORMATION);
}

