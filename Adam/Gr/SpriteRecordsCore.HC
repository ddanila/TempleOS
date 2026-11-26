#include "/Adam/Gr/SpriteElementSizeCore.HC"

I64 SpriteElemQuedBaseSize(I64 type)
{
  return sprite_elem_base_sizes[type&SPG_TYPE_MASK]+offset(CSprite.start);
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

