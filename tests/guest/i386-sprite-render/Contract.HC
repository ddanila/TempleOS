I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,32);
  U8 data[128];
  CSprite *s=data-offset(CSprite.start),*next;
  I64 mask=0,flags,color,thick,default_flags,default_thick;
  Bool default_ok;
  MemSet(data,0,sizeof(data));dc->color=RED;
  flags=dc->flags;color=dc->color;thick=dc->thick;
  default_flags=gr.dc->flags;default_thick=gr.dc->thick;
  gr.dc->flags&=~DCF_TRANSFORMATION;gr.dc->thick=7;
  DCThickScale;Sprite3(,0,0,0,data);
  default_ok=gr.dc->thick==7;
  gr.dc->flags=default_flags;gr.dc->thick=default_thick;
  Sprite3(dc,0,0,0,data);
  if(default_ok && GrPeek(dc,3,4)==BLACK && dc->flags==flags)mask|=1;
  s->type=SPT_PT;s->p.x1=3;s->p.y1=4;
  Sprite3(dc,0,0,0,data);
  if(GrPeek(dc,3,4)==RED && GrPeek(dc,4,4)==BLACK)mask|=2;
  MemSet(data,0,sizeof(data));s->type=SPT_SHIFT;s->p.x1=5;s->p.y1=6;
  next=(data+SpriteElemSize(s))-offset(CSprite.start);
  next->type=SPT_PT;next->p.x1=1;next->p.y1=2;
  Sprite3(dc,2,3,0,data);
  if(GrPeek(dc,8,11)==RED && GrPeek(dc,1,2)==BLACK)mask|=4;
  MemSet(data,0,sizeof(data));s->type=SPT_COLOR;s->c.color=GREEN;
  next=(data+SpriteElemSize(s))-offset(CSprite.start);
  next->type=SPT_PT;next->p.x1=12;next->p.y1=13;
  Sprite3(dc,0,0,0,data);
  if(GrPeek(dc,12,13)==GREEN && dc->color==color)mask|=8;
  next->p.x1=14;next->p.y1=15;
  Sprite3(dc,0,0,0,data,TRUE);
  if(GrPeek(dc,14,15)==BLACK && dc->color==color)mask|=16;
  if(dc->flags==flags && dc->thick==thick)mask|=32;
  DCDel(dc);return mask;
}
