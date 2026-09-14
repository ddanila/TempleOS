class CStringFailSource {
  U8 *bytes;
  I64 count,fail_at;
};
I64 StringFailRead(U8 *context,CCmpCtrl *cc)
{
  CStringFailSource *source=context;
  if(source->count==source->fail_at) return -1;
  return source->bytes[source->count++];
}
I64 StringFailureTest()
{
  CCmpCtrl cc; CLexFile file; CLexCharSource reader;
  CStringFailSource source;
  U8 input[8],output[16]; Bool done;
  I64 length,fail,i,j,result;
  reader.context=&source; reader.read=&StringFailRead;
  //Fail before plain input, after backslash, during either hex digit,
  //after an already decoded byte, and during dollar lookahead.
  for(j=0;j<3;j++) {
    input[0]=92; input[1]='x'; input[2]='A'; input[3]='b'; input[4]=34; length=5;
    if(j==1) { input[0]='a'; input[1]=92; input[2]='n'; input[3]=34; length=4; }
    if(j==2) { input[0]=36; input[1]=34; length=2; }
    source.bytes=input;
    for(fail=0;fail<length;fail++) {
      StringControlSeed(&cc,&file,input); source.count=0; source.fail_at=fail;
      for(i=0;i<16;i++) output[i]=0xA5;
      done=TRUE;
      result=LexStringChunk(&cc,output+2,8,&done,&reader);
      if(result!=-1 || done || source.count!=fail) return 120;
      if(output[0]!=0xA5 || output[1]!=0xA5) return 121;
      for(i=10;i<16;i++) if(output[i]!=0xA5) return 122;
    }
  }
  StringControlSeed(&cc,&file,input); source.count=0; source.fail_at=0;
  for(i=0;i<2;i++) {
    done=TRUE;
    if(LexStringChunk(&cc,0,i,&done,&reader) || done || source.count) return 123;
  }
  return 0;
}
