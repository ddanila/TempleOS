U0 SpriteMeshElem2Code(CDoc *doc,CSprite *tmpg)
{
  U8 buf1[STR_LEN];
  I64 i,col;
  CD3I32 *p;
  CMeshTri *tri;
  switch (tmpg->type&SPG_TYPE_MASK) {
    case SPT_MESH:
      DocPrint(doc,"{FALSE,");
      p=&tmpg->mu.u;
      col=0;
      for (i=0;i<tmpg->mu.vertex_cnt;i++,p++) {
	DocPrint(doc,"(%d,%d,%d)",p->x,p->y,p->z);
	if (i+1<tmpg->mu.vertex_cnt) DocPrint(doc,",");
	if (++col==4) {
	  DocPrint(doc,"\t//%d\n",i);
	  col=0;
	}
      }
      DocPrint(doc,":");
      tri=p;
      for (i=0;i<tmpg->mu.tri_cnt;i++,tri++) {
	DocPrint(doc,"(%s,%d,%d,%d)",Color2Str(buf1,tri->color),
	      tri->nums[0],tri->nums[1],tri->nums[2]);
	if (i+1<tmpg->mu.tri_cnt) DocPrint(doc,",");
	if (++col>=3 && i+1<tmpg->mu.tri_cnt) {
	  DocPrint(doc,"\n");
	  col=0;
	}
      }
      DocPrint(doc,"}");
      break;
    case SPT_SHIFTABLE_MESH:
      DocPrint(doc,"{TRUE,(%d,%d,%d):",tmpg->pmu.x,tmpg->pmu.y,tmpg->pmu.z);
      p=&tmpg->pmu.u;
      col=1;
      for (i=0;i<tmpg->pmu.vertex_cnt;i++,p++) {
	DocPrint(doc,"(%d,%d,%d)",p->x,p->y,p->z);
	if (i+1<tmpg->pmu.vertex_cnt) DocPrint(doc,",");
	if (++col==4) {
	  DocPrint(doc,"\t//%d\n",i);
	  col=0;
	}
      }
      DocPrint(doc,":");
      tri=p;
      for (i=0;i<tmpg->pmu.tri_cnt;i++,tri++) {
	DocPrint(doc,"(%s,%d,%d,%d)",Color2Str(buf1,tri->color),
	      tri->nums[0],tri->nums[1],tri->nums[2]);
	if (i+1<tmpg->pmu.tri_cnt) DocPrint(doc,",");
	if (++col>=3 && i+1<tmpg->pmu.tri_cnt) {
	  DocPrint(doc,"\n");
	  col=0;
	}
      }
      DocPrint(doc,"}");
      break;
  }
}

U0 SpritePolyElem2Code(CDoc *doc,CSprite *tmpg)
{
  I32 *ptr;
  I64 i,j,k,col,width_internal;
  switch (tmpg->type&SPG_TYPE_MASK) {
    case SPT_POLYLINE:
      ptr=&tmpg->nu.u;
      DocPrint(doc,"{");
      for (i=0;i<tmpg->nu.num;i++,ptr+=2) {
	DocPrint(doc,"(%d,%d)",ptr[0],ptr[1]);
	if (i+1<tmpg->nu.num) DocPrint(doc,",");
	if (i&3==3 && i+1<tmpg->nu.num)
	  DocPrint(doc,"\n");
      }
      DocPrint(doc,"}");
      break;
    case SPT_BSPLINE2:
    case SPT_BSPLINE3:
    case SPT_BSPLINE2_CLOSED:
    case SPT_BSPLINE3_CLOSED:
      ptr=&tmpg->nu.u;
      DocPrint(doc,"{");
      for (i=0;i<tmpg->nu.num;i++,ptr+=3) {
	DocPrint(doc,"(%d,%d,%d)",ptr[0],ptr[1],ptr[2]);
	if (i+1<tmpg->nu.num) DocPrint(doc,",");
	if (i&3==3 && i+1<tmpg->nu.num)
	  DocPrint(doc,"\n");
      }
      if (tmpg->type&SPG_TYPE_MASK==SPT_BSPLINE2||
	    tmpg->type&SPG_TYPE_MASK==SPT_BSPLINE3)
	DocPrint(doc,",FALSE}");
      else
	DocPrint(doc,",TRUE}");
      break;
    case SPT_POLYPT:
      DocPrint(doc,"{(%d,%d),",tmpg->npu.x,tmpg->npu.y);
      ptr=&tmpg->npu.u;
      col=16;
      for (i=0;i<tmpg->npu.num;i++) {
	DocPrint(doc,"%d",BFieldExtU32(ptr,i*3,3));
	if (++col>=64 && i+1<tmpg->npu.num) {
	  DocPrint(doc,"\n");
	  col=0;
	}
      }
      DocPrint(doc,"}");
      break;
    case SPT_BITMAP:
      DocPrint(doc,"{(%d,%d):(%d,%d),\n",tmpg->pwhu.x1,tmpg->pwhu.y1,
	    tmpg->pwhu.width,tmpg->pwhu.height);
      width_internal=(tmpg->pwhu.width+7)&~7;
      if (width_internal<80)
	k=width_internal;
      else
	k=64;
      ptr=&tmpg->pwhu.u;
      col=0;
      for (j=0;j<tmpg->pwhu.height;j++)
	for (i=0;i<width_internal;i++,ptr(U8 *)++) {
	  if (i>=tmpg->pwhu.width)
	    DocPrint(doc,"_");
	  else if (*ptr(U8 *)<16)
	    DocPrint(doc,"%X",*ptr(U8 *));
	  else
	    DocPrint(doc,"%c",CH_SHIFT_SPACE);
	  if (++col>=k && (i+1<width_internal||j+1<tmpg->pwhu.height)) {
	    DocPrint(doc,"\n");
	    col=0;
	  }
	}
      DocPrint(doc,"}");
      break;
    default:
      SpriteMeshElem2Code(doc,tmpg);
  }
}

U0 SpriteElem2Code(CDoc *doc,CSprite *tmpg)
{
  U8 buf1[STR_LEN],buf2[STR_LEN];
  if (!doc) doc=DocPut;
  DocPrint(doc,"%Z",tmpg->type&SPG_TYPE_MASK,"ST_SPRITE_ELEM_CODES");
  switch (tmpg->type&SPG_TYPE_MASK) {
    case SPT_COLOR:
      DocPrint(doc,"{%s}",
	    Color2Str(buf1,tmpg->c.color));
      break;
    case SPT_DITHER_COLOR:
      DocPrint(doc,"{%s}",
	    Color2Str(buf2,ROPF_DITHER|tmpg->d.dither_color.u8[0]|
	    tmpg->d.dither_color.u8[1]<<COLORROP_BITS));
      break;
    case SPT_TRANSFORM_ON:
      DocPrint(doc,"{ON}");
      break;
    case SPT_TRANSFORM_OFF:
      DocPrint(doc,"{OFF}");
      break;
    case SPT_LINE:
    case SPT_ARROW:
    case SPT_PLANAR_SYMMETRY:
      DocPrint(doc,"{(%d,%d),(%d,%d)}",tmpg->pp.x1,tmpg->pp.y1,
	    tmpg->pp.x2,tmpg->pp.y2);
      break;
    case SPT_RECT:
      DocPrint(doc,"{(%d,%d):(%d,%d)}",tmpg->pp.x1,tmpg->pp.y1,
	    tmpg->pp.x2-tmpg->pp.x1,tmpg->pp.y2-tmpg->pp.y1);
      break;
    case SPT_ROTATED_RECT:
      DocPrint(doc,"{(%d,%d):(%d,%d),%0.4f}",tmpg->ppa.x1,tmpg->ppa.y1,
	    tmpg->ppa.x2-tmpg->ppa.x1,tmpg->ppa.y2-tmpg->ppa.y1,
	    180/ã*Wrap(tmpg->ppa.angle));
      break;
    case SPT_PT:
    case SPT_FLOOD_FILL:
    case SPT_SHIFT:
      DocPrint(doc,"{(%d,%d)}",tmpg->p.x1,tmpg->p.y1);
      break;
    case SPT_FLOOD_FILL_NOT:
      DocPrint(doc,"{(%d,%d),TRUE}",tmpg->p.x1,tmpg->p.y1);
      break;
    case SPT_CIRCLE:
      DocPrint(doc,"{(%d,%d):%d}",tmpg->pr.x1,tmpg->pr.y1,tmpg->pr.radius);
      break;
    case SPT_THICK:
      DocPrint(doc,"{%d}",tmpg->t.thick);
      break;
    case SPT_ELLIPSE:
      DocPrint(doc,"{(%d,%d):(%d,%d),%0.4f}",tmpg->pwha.x1,tmpg->pwha.y1,
	    tmpg->pwha.width,tmpg->pwha.height,180/ã*Wrap(tmpg->pwha.angle));
      break;
    case SPT_POLYGON:
      DocPrint(doc,"{%d,(%d,%d):(%d,%d),%0.4f}",tmpg->pwhas.sides,
	    tmpg->pwhas.x1,tmpg->pwhas.y1,
	    tmpg->pwhas.width,tmpg->pwhas.height,
	    180/ã*Wrap(tmpg->pwhas.angle));
      break;
    case SPT_TEXT:
    case SPT_TEXT_BOX:
    case SPT_TEXT_DIAMOND:
      DocPrint(doc,"{(%d,%d),\"%Q\"}",tmpg->ps.x1,tmpg->ps.y1,tmpg->ps.st);
      break;
    default:
      SpritePolyElem2Code(doc,tmpg);
  }
  DocPrint(doc,";\n");
}

public U0 Sprite2Code(CDoc *doc=NULL,U8 *elems)
{//Sprite to text.
  CSprite *tmpg=elems-offset(CSprite.start);
  while (tmpg->type&SPG_TYPE_MASK) {
    SpriteElem2Code(doc,tmpg);
    tmpg(U8 *)+=SpriteElemSize(tmpg);
  }
}
