I32 triframe_seeds[24]={3,5,12,6,21,9,12,2,14,18,16,4,
1,1,30,1,15,14,9,14,9,5,23,8};
I64 triframe_permutation[18]={0,1,2,0,2,1,1,0,2,1,2,0,2,0,1,2,1,0};
I64 TriangleFrames()
{
  CDC *dc=DCNew(32,24);
  CD3I32 points[3];
  I64 test,orientation,permutation,clipped,index,plain=0,position=0,result;
  I64 plane=dc->width_internal*dc->height;
  I64 bytes_per_test=8+plane*5;
  U8 *frames=MAlloc(96*bytes_per_test);
  I64 (*triangle)(CDC *dc,CD3I32 *a,CD3I32 *b,CD3I32 *c);
  triangle=TRIANGLE_DRAW;
  DCDepthBufAlloc(dc);
  dc->color=RED;
  for(test=0;test<4;test++)for(orientation=0;orientation<2;orientation++)
    for(permutation=0;permutation<6;permutation++)for(clipped=0;clipped<2;clipped++) {
      for(index=0;index<3;index++) {
	points[index].x=triframe_seeds[test*6+index*2+orientation];
	points[index].y=triframe_seeds[test*6+index*2+1-orientation];
	points[index].z=9*index-12;
	if(clipped) {
	  points[index].x-=8;
	  points[index].y+=10;
	}
      }
      DCClear(dc);DCDepthBufRst(dc);
      result=(*triangle)(dc,&points[triframe_permutation[permutation*3]],&points[triframe_permutation[permutation*3+1]],
	&points[triframe_permutation[permutation*3+2]]);
      (frames+position)(I64 *)[0]=result;
      MemCpy(frames+position+8,dc->body,plane);
      MemCpy(frames+position+8+plane,dc->depth_buf,4*plane);
      position+=bytes_per_test;
      if(result>0)plain++;
    }
  if(position!=96*bytes_per_test || TRIANGLE_WRITE("Triangles.BIN",frames,position)<=0)
    plain=0;
  DCDel(dc);
  TRIANGLE_RELEASE(frames);
  return plain;
}
