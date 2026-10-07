I64 mesh_calls=0,mesh_bad_winding=0;
U0 MeshLight(CDC *dc,CD3I32 *a,CD3I32 *b,CD3I32 *c,I64 color)
{
  mesh_calls++;
  if((b->x-a->x)*(c->y-a->y)-(b->y-a->y)*(c->x-a->x)<=0)mesh_bad_winding++;
  dc->color=color;
}
U0 MeshQuad(CD3I32 *p,I64 x,I64 y,I64 w,I64 h)
{
  I64 i;p[0].x=x;p[0].y=y;p[1].x=x+w;p[1].y=y;
  p[2].x=x+w;p[2].y=y+h;p[3].x=x;p[3].y=y+h;
  for(i=0;i<4;i++)p[i].z=0;
}
Bool MeshCanvas(CDC *dc,I64 l,I64 t,I64 r,I64 b,Bool mirrored=FALSE)
{
  I64 x,y;Bool expected;
  for(y=0;y<dc->height;y++)for(x=0;x<dc->width;x++) {
    expected=l<=x<=r && t<=y<=b;
    if(mirrored)expected|=21<=x<=27 && 4<=y<=8;
    if((GrPeek0(dc,x,y)==RED)!=expected)return FALSE;
  }
  return TRUE;
}
I64 JRContract(I64 unused)
{
  CDC *dc=DCNew(32,24);CD3I32 p[4];CMeshTri tri[2];I64 mask=0,before;
  tri[0].nums[0]=0;tri[0].nums[1]=1;tri[0].nums[2]=2;
  tri[1].nums[0]=0;tri[1].nums[1]=2;tri[1].nums[2]=3;
  tri[0].color=tri[1].color=RED;
  dc->lighting=&MeshLight;dc->color=GREEN;MeshQuad(p,5,4,6,4);before=Fs->data_heap->used_u8s;
  if(Gr3Mesh(dc,4,p,0,tri)==0 && MeshCanvas(dc,-1,-1,-1,-1) && dc->color==GREEN && !mesh_calls)mask|=1;
  if(Gr3Mesh(dc,4,p,2,tri)>0 && MeshCanvas(dc,5,4,11,8) && dc->color==GREEN && mesh_calls==2 && !mesh_bad_winding)mask|=2;
  DCClear(dc);MeshQuad(p,2,2,6,4);dc->flags=DCF_TRANSFORMATION;dc->x=3;dc->y=2;dc->z=5;mesh_calls=0;
  if(Gr3Mesh(dc,4,p,2,tri)>0 && MeshCanvas(dc,5,4,11,8) && p[0].x==2 && p[0].y==2 && dc->flags==DCF_TRANSFORMATION && dc->color==GREEN && mesh_calls==2 && Fs->data_heap->used_u8s==before)mask|=4;
  DCClear(dc);MeshQuad(p,5,4,6,4);dc->flags=DCF_SYMMETRY|DCF_JUST_MIRROR;dc->sym.snx=GR_SCALE;dc->sym.sny=dc->sym.snz=0;dc->sym.sx=16;dc->sym.sy=dc->sym.sz=0;mesh_calls=0;
  if(Gr3Mesh(dc,4,p,2,tri)>0 && MeshCanvas(dc,21,4,27,8) && mesh_calls==2 && !mesh_bad_winding && dc->color==GREEN && Fs->data_heap->used_u8s==before)mask|=8;
  DCClear(dc);dc->flags=DCF_SYMMETRY;mesh_calls=0;
  if(Gr3Mesh(dc,4,p,2,tri)>0 && MeshCanvas(dc,5,4,11,8,TRUE) && mesh_calls==4 && !mesh_bad_winding && dc->flags==DCF_SYMMETRY && dc->color==GREEN && Fs->data_heap->used_u8s==before)mask|=16;
  DCClear(dc);dc->flags=0;MeshQuad(p,-2,-1,5,4);mesh_calls=0;
  if(Gr3Mesh(dc,4,p,2,tri)>0 && MeshCanvas(dc,0,0,3,3) && mesh_calls==2 && dc->color==GREEN && Fs->data_heap->used_u8s==before)mask|=32;
  DCDel(dc);return mask;
}
