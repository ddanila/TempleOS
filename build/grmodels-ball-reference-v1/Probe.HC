U0 ModelLog(U8 *text)
{
  while (*text) OutU8(0xE9,*text++);
}

U0 BallMeshProbe()
{
  BallDefineStruct spec;
  I64 first,second,third,repeated,bytes;
  U8 *sprite,line[160];
  BDInit(&spec);
  BDCorrect(&spec);
  b=CAlloc(sizeof(Ball));
  first=AddVertex(&spec,-12,3,7);
  second=AddVertex(&spec,20,-4,1);
  third=AddVertex(&spec,0,8,-9);
  repeated=AddVertex(&spec,-12,3,7);
  AddTri(&spec,12,first,second,third);
  if(first || second!=1 || third!=2 || repeated!=first ||
      b->vertex_cnt!=3 || b->tri_cnt!=1)
    ModelLog("FAIL ball vertices or indices\n");
  sprite=Ball2CSprite;
  bytes=1+8+3*sizeof(CD3I32)+sizeof(CMeshTri)+1;
  StrPrint(line,"EXPORT BallMesh.bin %X %X\n",sprite,bytes);
  ModelLog(line);
  Sleep(2000);
  Free(sprite);
  Free(b);
  b=NULL;
  ModelLog("BALL model captured\n");
}
