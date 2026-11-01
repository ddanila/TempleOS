#include "/Adam/Gr/Gr.HH"
Bool SISame(CDC *a,CDC *b)
{
  I64 x,y;
  for(y=0;y<a->height;y++)for(x=0;x<a->width;x++)
    if(GrPeek0(a,x,y)!=GrPeek0(b,x,y))return FALSE;
  return TRUE;
}
I64 SIContract()
{
  U8 a[64],b[64],*out;CSprite *sa=a-offset(CSprite.start),*sb=b-offset(CSprite.start),*sr;
  CDC *dc,*base;I64 *old_r,mask=0;
  MemSet(a,0,sizeof(a));MemSet(b,0,sizeof(b));
  sa->type=sb->type=SPT_PT;sa->p.x1=2;sa->p.y1=4;sb->p.x1=10;sb->p.y1=12;
  a[9]=b[9]=SPT_COLOR;a[10]=RED;b[10]=BLUE;
  if(SpriteSize(a)==12 && SpriteSize(b)==12)mask|=1;
  out=SpriteInterpolate(0,a,b);sr=out-offset(CSprite.start);
  if(sr->p.x1==2 && sr->p.y1==4 && out[10]==RED)mask|=2;Free(out);
  out=SpriteInterpolate(1,a,b);sr=out-offset(CSprite.start);
  if(sr->p.x1==10 && sr->p.y1==12 && out[10]==BLUE)mask|=4;Free(out);
  out=SpriteInterpolate(0.25,a,b);sr=out-offset(CSprite.start);
  if(sr->p.x1==4 && sr->p.y1==6 && out[10]==RED)mask|=8;Free(out);
  out=SpriteInterpolate(0.5,a,b);sr=out-offset(CSprite.start);
  if(sr->p.x1==6 && sr->p.y1==8 && out[10]==BLUE)mask|=16;Free(out);
  dc=DCNew(40,32);base=DCNew(40,32);dc->color=base->color=RED;
  old_r=dc->r;Sprite3B(base,8,6,0,a);Sprite3YB(dc,8,6,0,a,0);
  if(SISame(base,dc) && GrPeek0(dc,10,10)==RED && dc->r==old_r && !(dc->flags&DCF_TRANSFORMATION))mask|=32;
  DCDel(base);DCDel(dc);
  MemSet(a,0,sizeof(a));MemSet(b,0,sizeof(b));sa->type=sb->type=SPT_LINE;
  sa->pp.x1=-8;sa->pp.y1=2;sa->pp.x2=4;sa->pp.y2=6;
  sb->pp.x1=8;sb->pp.y1=10;sb->pp.x2=12;sb->pp.y2=14;
  out=SpriteInterpolate(0.5,a,b);sr=out-offset(CSprite.start);
  if(sr->pp.x1==0 && sr->pp.y1==6 && sr->pp.x2==8 && sr->pp.y2==10)mask|=64;Free(out);
  MemSet(a,0,sizeof(a));MemSet(b,0,sizeof(b));sa->type=sb->type=SPT_CIRCLE;
  sa->pr.x1=2;sa->pr.y1=4;sa->pr.radius=6;sb->pr.x1=10;sb->pr.y1=12;sb->pr.radius=14;
  out=SpriteInterpolate(0.5,a,b);sr=out-offset(CSprite.start);
  if(sr->pr.x1==6 && sr->pr.y1==8 && sr->pr.radius==10)mask|=128;Free(out);
  return mask;
}
I64 SICheck(){I64 v=SIContract;if(v!=255)throw('Sprite',TRUE);return v;}
