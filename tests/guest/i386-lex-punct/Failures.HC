class CPunctFailure { U8 *bytes; I64 count,fail_at; };
I64 PunctFailureRead(U8 *context,CCmpCtrl *cc)
{
  CPunctFailure *source=context;
  if(source->count==source->fail_at) return -1;
  return source->bytes[source->count++];
}
I64 PunctFailureTest()
{
  CCmpCtrl cc; CLexFile file; CLexCharSource reader; CPunctFailure source;
  U8 *input; I64 i,j,first,length; Bool finish;
  reader.context=&source; reader.read=&PunctFailureRead;
  for(i=0;i<4;i++) {
    switch(i) {
      case 0: input="* a /* b */ c */"; first=47; length=15; break;
      case 1: input="abc$$"; first=36; length=4; break;
      case 2: input="/abc\n"; first=47; length=5; break;
      case 3: input="<="; first=60; length=2; break;
    }
    source.bytes=input;
    for(j=0;j<length;j++) {
      PunctSeed(&cc,&file,input,0); source.count=0; source.fail_at=j;
      cc.token=77;
      if(LexPunctBody(&cc,first,&reader,&punct_tables,&finish)!=-1 ||
          source.count!=j || cc.token!=77) return 200+i;
    }
  }
  return 0;
}
