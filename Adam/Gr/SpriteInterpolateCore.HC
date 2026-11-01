public U8 *SpriteInterpolate(F64 t,U8 *elems0,U8 *elems1)
{//The two CSprite should be ident except for points shifted around.
//t ranges from 0.0 to 1.0.
  I64 i,t1=GR_SCALE*t,t0=GR_SCALE-t1;
  I32 *ptr0,*ptr1,*ptrr;
  CD3I32 *p0,*p1,*pr;
  U8 *res;
  CSprite *tmpg0=elems0-offset(CSprite.start),
	*tmpg1=elems1-offset(CSprite.start),*tmpgr;
  if (t<0.5) {
    i=SpriteSize(elems0),
	  res=MAlloc(i);
    MemCpy(res,elems0,i);
  } else {
    i=SpriteSize(elems1),
	  res=MAlloc(i);
    MemCpy(res,elems1,i);
  }
  tmpgr=res-offset(CSprite.start);
  while (tmpg0->type&SPG_TYPE_MASK) {
    if (tmpg0->type&SPG_TYPE_MASK!=tmpg1->type&SPG_TYPE_MASK)
      throw('Graphics');
    switch (tmpg0->type&SPG_TYPE_MASK) {
      case SPT_ROTATED_RECT:
	tmpgr->ppa.angle=(tmpg0->ppa.angle*t0+tmpg1->ppa.angle*t1)/GR_SCALE;
      case SPT_RECT:
      case SPT_LINE:
      case SPT_ARROW:
      case SPT_PLANAR_SYMMETRY:
	tmpgr->pp.x2=(tmpg0->pp.x2*t0+tmpg1->pp.x2*t1)>>32;
	tmpgr->pp.y2=(tmpg0->pp.y2*t0+tmpg1->pp.y2*t1)>>32;
      case SPT_TEXT:
      case SPT_TEXT_BOX:
      case SPT_TEXT_DIAMOND:
      case SPT_PT:
      case SPT_FLOOD_FILL:
      case SPT_FLOOD_FILL_NOT:
      case SPT_SHIFT:
	tmpgr->p.x1=(tmpg0->p.x1*t0+tmpg1->p.x1*t1)>>32;
	tmpgr->p.y1=(tmpg0->p.y1*t0+tmpg1->p.y1*t1)>>32;
	break;
      case SPT_CIRCLE:
	tmpgr->pr.radius=(tmpg0->pr.radius*t0+tmpg1->pr.radius*t1)>>32;
	tmpgr->pr.x1=(tmpg0->pr.x1*t0+tmpg1->pr.x1*t1)>>32;
	tmpgr->pr.y1=(tmpg0->pr.y1*t0+tmpg1->pr.y1*t1)>>32;
	break;
      case SPT_ELLIPSE:
      case SPT_POLYGON:
	tmpgr->pwha.x1=(tmpg0->pwha.x1*t0+tmpg1->pwha.x1*t1)>>32;
	tmpgr->pwha.y1=(tmpg0->pwha.y1*t0+tmpg1->pwha.y1*t1)>>32;
	tmpgr->pwha.width =(tmpg0->pwha.width *t0+tmpg1->pwha.width*t1)>>32;
	tmpgr->pwha.height=(tmpg0->pwha.height*t0+tmpg1->pwha.height*t1)>>32;
	break;
      case SPT_BITMAP:
	tmpgr->pwhu.x1=(tmpg0->pwhu.x1*t0+tmpg1->pwhu.x1*t1)>>32;
	tmpgr->pwhu.y1=(tmpg0->pwhu.y1*t0+tmpg1->pwhu.y1*t1)>>32;
	break;
      case SPT_POLYLINE:
	ptr0=&tmpg0->nu.u;
	ptr1=&tmpg1->nu.u;
	ptrr=&tmpgr->nu.u;
	for (i=0;i<tmpg0->nu.num;i++) {
	  ptrr[i<<1]=(ptr0[i<<1]*t0+ptr1[i<<1]*t1)>>32;
	  ptrr[i<<1+1]=(ptr0[i<<1+1]*t0+ptr1[i<<1+1]*t1)>>32;
	}
	break;
      case SPT_POLYPT:
	tmpgr->npu.x=(tmpg0->npu.x*t0+tmpg1->npu.x*t1)>>32;
	tmpgr->npu.y=(tmpg0->npu.y*t0+tmpg1->npu.y*t1)>>32;
	break;
      case SPT_BSPLINE2:
      case SPT_BSPLINE3:
      case SPT_BSPLINE2_CLOSED:
      case SPT_BSPLINE3_CLOSED:
	p0=&tmpg0->nu.u;
	p1=&tmpg1->nu.u;
	pr=&tmpgr->nu.u;
	for (i=0;i<tmpg0->nu.num;i++) {
	  pr[i].x=(p0[i].x*t0+p1[i].x*t1)>>32;
	  pr[i].y=(p0[i].y*t0+p1[i].y*t1)>>32;
	  pr[i].z=(p0[i].z*t0+p1[i].z*t1)>>32;
	}
	break;
      case SPT_MESH:
	p0=&tmpg0->mu.u;
	p1=&tmpg1->mu.u;
	pr=&tmpgr->mu.u;
	for (i=0;i<tmpg0->mu.vertex_cnt;i++) {
	  pr[i].x=(p0[i].x*t0+p1[i].x*t1)>>32;
	  pr[i].y=(p0[i].y*t0+p1[i].y*t1)>>32;
	  pr[i].z=(p0[i].z*t0+p1[i].z*t1)>>32;
	}
	break;
      case SPT_SHIFTABLE_MESH:
	p0=&tmpg0->pmu.u;
	p1=&tmpg1->pmu.u;
	pr=&tmpgr->pmu.u;
	for (i=0;i<tmpg0->pmu.vertex_cnt;i++) {
	  pr[i].x=(p0[i].x*t0+p1[i].x*t1)>>32;
	  pr[i].y=(p0[i].y*t0+p1[i].y*t1)>>32;
	  pr[i].z=(p0[i].z*t0+p1[i].z*t1)>>32;
	}
	break;
    }
    tmpg0(U8 *)+=SpriteElemSize(tmpg0);
    tmpg1(U8 *)+=SpriteElemSize(tmpg1);
    tmpgr(U8 *)+=SpriteElemSize(tmpgr);
  }
  return res;
}
