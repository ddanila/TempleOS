I64 CharFailureTest()
{
  CCmpCtrl cc; CLexFile file; CLexCharSource reader; CStringFailSource source;
  U8 input[16]; I64 i,fail;
  reader.context=&source; reader.read=&StringFailRead; source.bytes=input;
  input[0]=92; input[1]='x'; input[2]='A'; input[3]='b'; input[4]=36; input[5]=36; input[6]=39;
  for(fail=0;fail<7;fail++) {
    StringControlSeed(&cc,&file,input); source.count=0; source.fail_at=fail;
    cc.cur_i64=0x123456789ABCDEF0; cc.token=77;
    if(LexCharBody(&cc,&reader)!=-1 || source.count!=fail ||
        cc.cur_i64!=0x123456789ABCDEF0 || cc.token!=77) return 141;
  }
  for(i=0;i<9;i++) input[i]=65+i;
  input[9]=39; input[10]=0;
  StringControlSeed(&cc,&file,input); source.count=0; source.fail_at=99;
  cc.cur_i64=123; cc.token=77;
  if(LexCharBody(&cc,&reader)!=-2 || source.count!=9 || cc.cur_i64!=123 || cc.token!=77) return 142;
  //Failure while checking the closing quote after eight bytes is a reader error.
  source.count=0; source.fail_at=8;
  if(LexCharBody(&cc,&reader)!=-1 || source.count!=8 || cc.cur_i64!=123 || cc.token!=77) return 143;
  return 0;
}
