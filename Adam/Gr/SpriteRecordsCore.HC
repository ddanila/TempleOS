I64 sprite_elem_base_sizes[SPT_TYPES_NUM]={
  sizeof(CSpriteBase),		//SPT_END
  sizeof(CSpriteColor),		//SPT_COLOR
  sizeof(CSpriteDitherColor),	//SPT_DITHER_COLOR
  sizeof(CSpriteT),		//SPT_THICK
  sizeof(CSpritePtPt),		//SPT_PLANAR_SYMMETRY
  sizeof(CSpriteBase),		//SPT_TRANSFORM_ON
  sizeof(CSpriteBase),		//SPT_TRANSFORM_OFF
  sizeof(CSpritePt),		//SPT_SHIFT
  sizeof(CSpritePt),		//SPT_PT
  sizeof(CSpriteNumPtU8s),	//SPT_POLYPT
  sizeof(CSpritePtPt),		//SPT_LINE
  sizeof(CSpriteNumU8s),	//SPT_POLYLINE
  sizeof(CSpritePtPt),		//SPT_RECT
  sizeof(CSpritePtPtAng),	//SPT_ROTATED_RECT
  sizeof(CSpritePtRad),		//SPT_CIRCLE
  sizeof(CSpritePtWHAng),	//SPT_ELLIPSE
  sizeof(CSpritePtWHAngSides),	//SPT_POLYGON
  sizeof(CSpriteNumU8s),	//SPT_BSPLINE2
  sizeof(CSpriteNumU8s),	//SPT_BSPLINE2_CLOSED
  sizeof(CSpriteNumU8s),	//SPT_BSPLINE3
  sizeof(CSpriteNumU8s),	//SPT_BSPLINE3_CLOSED
  sizeof(CSpritePt),		//SPT_FLOOD_FILL
  sizeof(CSpritePt),		//SPT_FLOOD_FILL_NOT
  sizeof(CSpritePtWHU8s),	//SPT_BITMAP
  sizeof(CSpriteMeshU8s),	//SPT_MESH
  sizeof(CSpritePtMeshU8s),	//SPT_SHIFTABLE_MESH
  sizeof(CSpritePtPt),		//SPT_ARROW
  sizeof(CSpritePtStr),		//SPT_TEXT
  sizeof(CSpritePtStr),		//SPT_TEXT_BOX
  sizeof(CSpritePtStr),		//SPT_TEXT_DIAMOND
};

I64 SpriteElemQuedBaseSize(I64 type)
{
  return sprite_elem_base_sizes[type&SPG_TYPE_MASK]+offset(CSprite.start);
}

I64 SpriteElemSize(CSprite *tmpg)
{
  I64 i=sprite_elem_base_sizes[tmpg->type&SPG_TYPE_MASK];
  switch (tmpg->type&SPG_TYPE_MASK) {
    case SPT_POLYLINE:
      i+=tmpg->nu.num*sizeof(CD2I32);
      break;
    case SPT_TEXT:
    case SPT_TEXT_BOX:
    case SPT_TEXT_DIAMOND:
      i+=StrLen(tmpg->ps.st)+1;
      break;
    case SPT_BITMAP:
      i+=((tmpg->pwhu.width+7)&~7)*tmpg->pwhu.height;
      break;
    case SPT_POLYPT:
      i+=(tmpg->npu.num*3+7)>>3;
      break;
    case SPT_BSPLINE2:
    case SPT_BSPLINE3:
    case SPT_BSPLINE2_CLOSED:
    case SPT_BSPLINE3_CLOSED:
      i+=tmpg->nu.num*sizeof(CD3I32);
      break;
    case SPT_MESH:
      i+=tmpg->mu.vertex_cnt*sizeof(CD3I32)+
	    tmpg->mu.tri_cnt*sizeof(CMeshTri);
      break;
    case SPT_SHIFTABLE_MESH:
      i+=tmpg->pmu.vertex_cnt*sizeof(CD3I32)+
	    tmpg->pmu.tri_cnt*sizeof(CMeshTri);
      break;
  }
  return i;
}

public I64 SpriteSize(U8 *elems)
{//Walk sprite elements and return size of sprite as binary data.
  CSprite *tmpg=elems-offset(CSprite.start),*tmpg1=tmpg;
  while (tmpg->type&SPG_TYPE_MASK)
    tmpg(U8 *)+=SpriteElemSize(tmpg);
  return tmpg(U8 *)-tmpg1(U8 *)+sprite_elem_base_sizes[SPT_END];
}

I64 SpriteTypeMask(U8 *elems)
{
  I64 res=0;
  CSprite *tmpg=elems-offset(CSprite.start);
  while (tmpg->type&SPG_TYPE_MASK) {
    if (tmpg->type&SPG_TYPE_MASK>=SPT_TYPES_NUM)
      return 1<<SPT_TYPES_NUM;
    Bts(&res,tmpg->type&SPG_TYPE_MASK);
    tmpg(U8 *)+=SpriteElemSize(tmpg);
  }
  return res;
}

