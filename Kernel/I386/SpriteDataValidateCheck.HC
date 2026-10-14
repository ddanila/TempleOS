#include "/Adam/Gr/Gr.HH"
#include "/Adam/Gr/SpriteRecordsCore.HC"
#include "/Adam/Gr/SpriteDataValidateCore.HC"
I64 SpriteDataValidateCheck()
{
  U8 *s=CAlloc(80);
  CSpritePtPt *r;
  CSpriteNumU8s *line=s;
  CSpritePtWHU8s *bitmap=s;
  CSpriteMeshU8s *mesh=s;
  CMeshTri *tri;
  I64 count=0,size;
  if(!SpriteDataValidateCore(NULL,1))count++;
  if(!SpriteDataValidateCore(s,0))count++;
  if(SpriteDataValidateCore(s,1))count++;
  if(!SpriteDataValidateCore(s,2))count++;
  s[0]=SPT_COLOR;s[1]=4;
  if(SpriteDataValidateCore(s,3))count++;
  if(!SpriteDataValidateCore(s,2))count++;
  s[0]=127;
  if(!SpriteDataValidateCore(s,3))count++;
  s[0]=SPT_COLOR;s[1]=4;r=s+sizeof(CSpriteColor);
  r->type=SPT_RECT;r->x1=-4;r->y1=2;r->x2=8;r->y2=6;
  if(SpriteDataValidateCore(s,20))count++;
  if(!SpriteDataValidateCore(s,19))count++;
  MemSet(s,0,80);s[0]=SPT_TEXT;s[sizeof(CSpritePtStr)]='A';
  if(SpriteDataValidateCore(s,sizeof(CSpritePtStr)+3))count++;
  if(!SpriteDataValidateCore(s,sizeof(CSpritePtStr)+1))count++;
  MemSet(s,0,80);line->type=SPT_POLYLINE;line->num=-1;
  if(!SpriteDataValidateCore(s,sizeof(CSpriteNumU8s)+1))count++;
  line->num=0x7FFFFFFF;
  if(!SpriteDataValidateCore(s,sizeof(CSpriteNumU8s)+1))count++;
  MemSet(s,0,80);bitmap->type=SPT_BITMAP;bitmap->width=-1;
  if(!SpriteDataValidateCore(s,sizeof(CSpritePtWHU8s)+1))count++;
  MemSet(s,0,80);mesh->type=SPT_MESH;mesh->vertex_cnt=1;mesh->tri_cnt=1;
  tri=s+sizeof(CSpriteMeshU8s)+sizeof(CD3I32);
  size=sizeof(CSpriteMeshU8s)+sizeof(CD3I32)+sizeof(CMeshTri)+1;
  if(SpriteDataValidateCore(s,size))count++;
  tri->nums[1]=1;
  if(!SpriteDataValidateCore(s,size))count++;
  tri->nums[1]=0;
  if(!SpriteDataValidateCore(s,size-1))count++;
  MemSet(s,0,80);s[0]=SPT_COLOR|SPF_SEL;s[1]=4;
  if(SpriteDataValidateCore(s,3))count++;
  Free(s);return count;
}
