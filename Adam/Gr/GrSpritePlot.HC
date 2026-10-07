#help_index "Graphics/Sprite;Sprites"
/*
$LK,"CSprite",A="MN:CSprite"$s are stored as a sequence of var
length operations with a 1-byte $LK,"type",A="MN:SPT_PT"$ leading
each operation.  They are stored, one after another,
in a chunk of memory terminated by a $LK,"zero",A="MN:SPT_END"$.
$LK,"Sprite3",A="MN:Sprite3"$() shows how the $LK,"CSprite",A="MN:CSprite"$ unions are used.

$LK,"SpriteElemSize",A="MN:SpriteElemSize"$() will return the size of a single
element, while $LK,"SpriteSize",A="MN:SpriteSize"$() will return the size
of an entire list.  Look at $LK,"sprite_elem_base_sizes",A="MN:sprite_elem_base_sizes"$.

See $MA-X+PU,"::/Apps/GrModels",LM="Cd(\"::/Apps/GrModels\");Dir;View;\n"$ for an example of
making CSprite by hand.  It uses $LK,"SPT_MESH",A="MN:SPT_MESH"$,
one of the most complicated.
*/

#include "::/Adam/Gr/SpriteRenderCore.HC"

public U0 Sprite3B(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems)
{//Plot a sprite into a CDC, post transform xyz translation.
  I64 old_x=dc->x,old_y=dc->y,old_z=dc->z,
	old_flags=dc->flags&DCF_TRANSFORMATION;
  dc->x=x; dc->y=y; dc->z=z;
  dc->flags|=DCF_TRANSFORMATION;
  Sprite3(dc,0,0,0,elems);
  dc->x=old_x; dc->y=old_y; dc->z=old_z;
  dc->flags=dc->flags&~DCF_TRANSFORMATION|old_flags;
}

public U0 Sprite3Mat4x4B(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,I64 *m)
{//Plot rotated by matrix.
  I64 r[16],*old_r=dc->r,new_m[16],
	old_flags=dc->flags&DCF_TRANSFORMATION;
  MemCpy(new_m,m,16*sizeof(I64));
  dc->flags|=DCF_TRANSFORMATION;
  Mat4x4TranslationAdd(new_m,x,y,z);
  dc->r=Mat4x4MulMat4x4Equ(r,old_r,new_m);
  Sprite3(dc,0,0,0,elems);
  dc->r=old_r;
  dc->flags=dc->flags&~DCF_TRANSFORMATION|old_flags;
}

public U0 Sprite3XB(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,F64 è=0)
{//Plot rotated around X axis.
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotX(r,è);
  Sprite3Mat4x4B(dc,x,y,z,elems,r);
}

public U0 Sprite3YB(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,F64 ê=0)
{//Plot rotated around Y axis.
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotY(r,ê);
  Sprite3Mat4x4B(dc,x,y,z,elems,r);
}

public U0 Sprite3ZB(CDC *dc=gr.dc,I64 x,I64 y,I64 z,U8 *elems,F64 é=0)
{//Plot rotated around Z axis.
  I64 r[16];
  Mat4x4IdentEqu(r);
  Mat4x4RotZ(r,é);
  Sprite3Mat4x4B(dc,x,y,z,elems,r);
}

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

public CDC *Sprite2DC(U8 *elems)
{//Convert sprite to device context.
  CDC *res;
  I64 min_x,max_x,min_y,max_y;
  SpriteExtents(elems,&min_x,&max_x,&min_y,&max_y);
  res=DCNew(max_x-min_x+1,max_y-min_y+1);
  Sprite3(res,-min_x,-min_y,0,elems);
  return res;
}

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

#help_index "Graphics/Sprite;DolDoc/Output;StdOut/DolDoc"
public CDocEntry *DocSprite(CDoc *doc=NULL,U8 *elems,U8 *fmt=NULL)
{//Put a sprite into a document.  You can, optionally, supply a fmt string
//for $LK,"DolDoc",A="FI:::/Doc/DolDocOverview.DD"$ cmd with a %d for the bin_num.
  I64 size;
  U8 *st;
  Bool unlock;
  CDocEntry *doc_e;
  CDocBin *tmpb;
  if (!doc && !(doc=DocPut)) return NULL;
  unlock=DocLock(doc);
  size=SpriteSize(elems);
  tmpb=CAlloc(sizeof(CDocBin),doc->mem_task);
  tmpb->size=size;
  tmpb->data=MAlloc(size,doc->mem_task);
  MemCpy(tmpb->data,elems,size);
  tmpb->num=doc->cur_bin_num;
  tmpb->use_cnt=1;
  QueIns(tmpb,doc->bin_head.last);
  if (fmt)
    st=MStrPrint(fmt,doc->cur_bin_num++);
  else
    st=MStrPrint("$$SP,\"\",BI=%d$$",doc->cur_bin_num++);
  doc_e=DocPrint(doc,"%s",st);
  Free(st);
  doc_e->bin_data=tmpb;
  if (doc_e && doc_e->de_flags&DOCEF_TAG && doc_e->tag && *doc_e->tag)
    tmpb->tag=StrNew(doc_e->tag,doc->mem_task);
  if (unlock)
    DocUnlock(doc);
  return doc_e;
}

public CDocEntry *Sprite(U8 *elems,U8 *fmt=NULL)
{//Put sprite to the command-line, $LK,"DocPut",A="MN:DocPut"$.
//If you set fmt, then include dollars ("$$SP ...$$") and leave %d for num.
  CDoc *doc;
  if (doc=DocPut)
    return DocSprite(doc,elems,fmt);
  return NULL;
}
