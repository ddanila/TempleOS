I64 sr_sizes[30]={1,2,3,5,17,1,1,9,9,13,17,5,17,25,13,25,29,5,5,5,5,9,9,17,9,21,17,10,10,10};
I64 JRContract(I64 unused)
{
  U8 data[2048];
  I64 i,used=0,mask=0;
  CSprite *s=data-offset(CSprite.start);
  Bool ok=TRUE;
  MemSet(data,0,sizeof(data));
  if(!SpriteTypeMask(data) && SpriteSize(data)==1)mask|=1;
  for(i=1;i<30;i++) {
    MemSet(data,0,sizeof(data));s->type=i;
    if(SpriteElemSize(s)!=sr_sizes[i])ok=FALSE;
  }
  if(ok)mask|=2;
  MemSet(data,0,sizeof(data));
  for(i=1;i<30;i++) {data[used]=i;used+=sr_sizes[i];}
  if(SpriteTypeMask(data)==0x3FFFFFFE && SpriteSize(data)==used+1)mask|=4;
  data[0]|=SPF_SEL;
  if(SpriteTypeMask(data)==0x3FFFFFFE && SpriteSize(data)==used+1)mask|=8;
  MemSet(data,0,sizeof(data));s->type=SPT_TYPES_NUM;
  if(SpriteTypeMask(data)==1<<SPT_TYPES_NUM)mask|=16;
  MemSet(data,0,sizeof(data));s->type=SPT_POLYLINE;s->nu.num=2;
  ok=SpriteElemSize(s)==21;
  MemSet(data,0,sizeof(data));s->type=SPT_POLYPT;s->npu.num=3;
  ok=ok && SpriteElemSize(s)==15;
  MemSet(data,0,sizeof(data));s->type=SPT_BITMAP;s->pwhu.width=9;s->pwhu.height=2;
  ok=ok && SpriteElemSize(s)==49;
  MemSet(data,0,sizeof(data));s->type=SPT_BSPLINE3;s->nu.num=2;
  ok=ok && SpriteElemSize(s)==29;
  MemSet(data,0,sizeof(data));s->type=SPT_MESH;s->mu.vertex_cnt=2;s->mu.tri_cnt=1;
  ok=ok && SpriteElemSize(s)==49;
  MemSet(data,0,sizeof(data));s->type=SPT_SHIFTABLE_MESH;s->pmu.vertex_cnt=2;s->pmu.tri_cnt=1;
  ok=ok && SpriteElemSize(s)==61;
  if(ok)mask|=32;
  return mask;
}
