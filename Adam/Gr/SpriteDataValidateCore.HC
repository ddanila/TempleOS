//Bounds checks for the original packed sprite records, before Sprite3 walks them.
Bool SpriteDataCountFits(I64 count,I64 width,I64 available)
{
  return count>=0 && width>0 && count<=available/width;
}
Bool SpriteDataValidateCore(U8 *data,I64 size)
{
  I64 at=0,type,base,left,extra,count,width,height,vertices,triangles,i,j;
  CSprite *s;
  CMeshTri *tri;
  if(!data || size<1) return FALSE;
  while(at<size) {
    type=data[at]&SPG_TYPE_MASK;
    if(type>=SPT_TYPES_NUM) return FALSE;
    base=sprite_elem_base_sizes[type];left=size-at;
    if(base<1 || base>left) return FALSE;
    if(type==SPT_END) return at+base==size;
    s=data+at-offset(CSprite.start);left-=base;extra=0;
    switch(type) {
      case SPT_TEXT: case SPT_TEXT_BOX: case SPT_TEXT_DIAMOND:
        while(extra<left && data[at+base+extra]) extra++;
        if(extra==left) return FALSE;
        extra++;
        break;
      case SPT_POLYLINE:
        count=s->nu.num;
        if(!SpriteDataCountFits(count,sizeof(CD2I32),left)) return FALSE;
        extra=count*sizeof(CD2I32);
        break;
      case SPT_BSPLINE2: case SPT_BSPLINE2_CLOSED:
      case SPT_BSPLINE3: case SPT_BSPLINE3_CLOSED:
        count=s->nu.num;
        if(!SpriteDataCountFits(count,sizeof(CD3I32),left)) return FALSE;
        extra=count*sizeof(CD3I32);
        break;
      case SPT_POLYPT:
        count=s->npu.num;
        if(count<0) return FALSE;
        extra=(count*3+7)>>3;
        if(extra>left) return FALSE;
        break;
      case SPT_BITMAP:
        width=s->pwhu.width;height=s->pwhu.height;
        if(width<0 || height<0) return FALSE;
        width=(width+7)&~7;
        if(width) {
          if(!SpriteDataCountFits(height,width,left)) return FALSE;
          extra=height*width;
        }
        break;
      case SPT_MESH: case SPT_SHIFTABLE_MESH:
        if(type==SPT_MESH) {vertices=s->mu.vertex_cnt;triangles=s->mu.tri_cnt;}
        else {vertices=s->pmu.vertex_cnt;triangles=s->pmu.tri_cnt;}
        if(!SpriteDataCountFits(vertices,sizeof(CD3I32),left)) return FALSE;
        extra=vertices*sizeof(CD3I32);
        if(!SpriteDataCountFits(triangles,sizeof(CMeshTri),left-extra)) return FALSE;
        tri=data+at+base+extra;
        for(i=0;i<triangles;i++) for(j=0;j<3;j++)
          if(tri[i].nums[j]<0 || tri[i].nums[j]>=vertices) return FALSE;
        extra+=triangles*sizeof(CMeshTri);
        break;
    }
    at+=base+extra;
  }
  return FALSE;
}
