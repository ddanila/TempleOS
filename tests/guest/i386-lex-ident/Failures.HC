class CIdentFailure { I64 count,fail_at; };
I64 IdentFailureRead(U8 *context,CCmpCtrl *cc)
{
  CIdentFailure *source=context;
  if(source->count==source->fail_at) return -1;
  source->count++; return 'b';
}
I64 IdentFailureTest()
{
  CCmpCtrl cc; CLexFile file; CLexCharSource reader; CIdentFailure source;
  U8 output[146],input[2]; I64 i,j,result;
  input[0]=0; reader.context=&source; reader.read=&IdentFailureRead;
  for(i=0;i<4;i++) {
    IdentSeed(&cc,&file,input); source.count=0; source.fail_at=i;
    for(j=0;j<146;j++) output[j]=0xA5;
    if(LexIdentRead(&cc,'a',output+1,144,&reader)!=-1 || source.count!=i || output[0]!=0xA5) return 120;
    if(output[1]!='a') return 121;
    for(j=i+2;j<146;j++) if(output[j]!=0xA5) return 122;
  }
  source.count=0; source.fail_at=999;
  for(j=0;j<146;j++) output[j]=0xA5;
  if(LexIdentRead(&cc,'a',output+1,144,&reader)!=-2 || source.count!=143 || output[0]!=0xA5 || output[145]!=0xA5) return 123;
  return 0;
}
