#include "/Adam/Gr/SpriteBaseSizes.HC"

public I64 SpriteElemSize(CSprite *tmpg)
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
