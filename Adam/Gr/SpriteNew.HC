#help_index "Graphics/Sprite;Sprites"
#help_file "::/Doc/Sprite"

U8 polypt_map[9]={0,1,2,3,0,4,5,6,7};

#include "/Adam/Gr/SpriteRecordsCore.HC"

U0 SpriteSelAll(U8 *elems,Bool val)
{
  CSprite *tmpg=elems-offset(CSprite.start);
  while (tmpg->type&SPG_TYPE_MASK) {
    BEqu(&tmpg->type,SPf_SEL,val);
    tmpg(U8 *)+=SpriteElemSize(tmpg);
  }
}

public U8 *DC2Sprite(CDC *tmpb)
{//Convert device context to sprite.
  CSprite *tmpg;
  tmpg=CAlloc(sprite_elem_base_sizes[SPT_BITMAP]+
	tmpb->width_internal*tmpb->height+
	sprite_elem_base_sizes[SPT_END])
  (U8 *)-offset(CSprite.start);
  tmpg->type=SPT_BITMAP;
  tmpg->pwhu.width=tmpb->width;
  tmpg->pwhu.height=tmpb->height;
  tmpg->pwhu.x1=0;
  tmpg->pwhu.y1=0;
  MemCpy(&tmpg->pwhu.u,tmpb->body,tmpb->width_internal*tmpb->height);
  return tmpg(U8 *)+offset(CSprite.start);
}

public U8 *SpriteElem2Summary(CSprite *tmpg)
{//Study $LK,"::/Demo/Graphics/SpriteText.HC"$.
  U8 buf[STR_LEN],buf2[STR_LEN];
  I32 *ptr;
  StrPrint(buf,"%Z",tmpg->type&SPG_TYPE_MASK,"ST_SPRITE_ELEM_TYPES");
  switch (tmpg->type&SPG_TYPE_MASK) {
    case SPT_COLOR:
      CatPrint(buf," %s",Color2Str(buf2,tmpg->c.color));
      break;
    case SPT_DITHER_COLOR:
      CatPrint(buf," %s",Color2Str(buf2,ROPF_DITHER|tmpg->d.dither_color.u8[0]|
	    tmpg->d.dither_color.u8[1]<<COLORROP_BITS));
      break;
    case SPT_PT:
    case SPT_FLOOD_FILL:
    case SPT_FLOOD_FILL_NOT:
    case SPT_SHIFT:
      CatPrint(buf," (%d,%d)",tmpg->p.x1,tmpg->p.y1);
      break;
    case SPT_LINE:
    case SPT_ARROW:
    case SPT_PLANAR_SYMMETRY:
    case SPT_RECT:
    case SPT_ROTATED_RECT:
      CatPrint(buf," (%d,%d),(%d,%d)",tmpg->pp.x1,tmpg->pp.y1,
	    tmpg->pp.x2,tmpg->pp.y2);
      break;
    case SPT_CIRCLE:
      CatPrint(buf," (%d,%d):%dR",tmpg->pr.x1,tmpg->pr.y1,tmpg->pr.radius);
      break;
    case SPT_THICK:
      CatPrint(buf," %d",tmpg->t.thick);
      break;
    case SPT_TEXT:
    case SPT_TEXT_BOX:
    case SPT_TEXT_DIAMOND:
      CatPrint(buf," %d,%d:%-16t$$Q",tmpg->ps.x1,tmpg->ps.y1,tmpg->ps.st);
      break;
    case SPT_POLYLINE:
    case SPT_POLYPT:
      ptr=&tmpg->npu.x;
      CatPrint(buf," %d (%d,%d)",tmpg->npu.num,ptr[0],ptr[1]);
      break;
    case SPT_ELLIPSE:
    case SPT_POLYGON:
    case SPT_BITMAP:
      CatPrint(buf," (%d,%d):%dW,%dH",tmpg->pwhu.x1,tmpg->pwhu.y1,
	    tmpg->pwhu.width,tmpg->pwhu.height);
      break;
    case SPT_BSPLINE2:
    case SPT_BSPLINE3:
    case SPT_BSPLINE2_CLOSED:
    case SPT_BSPLINE3_CLOSED:
      CatPrint(buf," %d",tmpg->nu.num);
      break;
    case SPT_MESH:
      CatPrint(buf," %dV,%dT",tmpg->mu.vertex_cnt,tmpg->mu.tri_cnt);
      break;
    case SPT_SHIFTABLE_MESH:
      CatPrint(buf," %dV,%dT",tmpg->pmu.vertex_cnt,tmpg->pmu.tri_cnt);
      break;
  }
  return StrNew(buf);
}
