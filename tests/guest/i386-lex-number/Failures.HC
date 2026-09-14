class CNumberFailSource {
  U8 *input;
  I64 position,fail_at;
};
I64 NumberFailRead(U8 *context,CCmpCtrl *cc)
{
  CNumberFailSource *source=context;
  if(source->position==source->fail_at) return -1;
  return source->input[source->position++];
}
I64 NumberFailureTest()
{
  CCmpCtrl cc; CLexFile file; CLexCharSource reader;
  CNumberFailSource source;
  U8 *input; I64 mode,position,length,result;
  reader.context=&source; reader.read=&NumberFailRead;
  for(mode=0;mode<5;mode++) {
    input="12.3e-4;"; length=8;
    if(mode==1) { input="0xAb;"; length=5; }
    if(mode==2) { input="0b10;"; length=5; }
    if(mode==3) { input=".12;"; length=4; }
    if(mode==4) { input="...;"; length=3; }
    for(position=1;position<length;position++) {
      NumberControlSeed(&cc,&file,input,0);
      cc.cur_i64=0x123456789ABCDEF0;
      source.input=input; source.position=1; source.fail_at=position;
      result=LexNumberBody(&cc,input[0],&reader);
      if(result!=-1 || source.position!=position || cc.cur_i64!=0x123456789ABCDEF0) return 12000+mode*10+position;
    }
  }
  NumberControlSeed(&cc,&file,input,0); source.position=0; source.fail_at=0;
  if(LexNumberBody(&cc,'+',&reader)!=-1 || source.position) return 12100;
  //Consecutive calls exercise replay of the second dot and following digit.
  input="1..2...3;"; NumberControlSeed(&cc,&file,input,0); position=0;
  if(NumberRead(&cc,&position)!=TK_I64 || cc.cur_i64!=1 ||
      NumberRead(&cc,&position)!=TK_DOT_DOT ||
      NumberRead(&cc,&position)!=TK_I64 || cc.cur_i64!=2 ||
      NumberRead(&cc,&position)!=TK_ELLIPSIS ||
      NumberRead(&cc,&position)!=TK_I64 || cc.cur_i64!=3 || cc.last_U16!=';') return 12101;
  return 0;
}
