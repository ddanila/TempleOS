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
