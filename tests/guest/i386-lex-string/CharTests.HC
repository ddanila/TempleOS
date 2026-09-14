//Complete inputs include the opening quote and a trailing semicolon.
I64 CharCase(U8 *input,I64 expected,I64 consumed,I64 newlines=0)
{
  CCmpCtrl cc; CLexFile file; I64 lines=0;
  StringControlSeed(&cc,&file,input); cc.flags&=~CCF_IN_QUOTES;
  cc.dollar_cnt=7;
  if(CharToken(&cc,&lines)!=TK_CHAR_CONST || cc.cur_i64!=expected ||
      cc.cur_buf_ptr!=input+consumed || cc.last_U16!=59 ||
      !(cc.flags&CCF_USE_LAST_U16) || cc.dollar_cnt!=7 ||
      file.line_num!=newlines+1) return 140;
  return 0;
}
I64 CharTest()
{
  U8 input[32],*hex="0123456789abcdef";
  I64 i,j,k,result,value;
  for(i=0;i<=8;i++) {
    input[0]=39; value=0;
    for(j=0;j<i;j++) { input[j+1]=65+j; value|=(65+j)<<(j*8); }
    input[i+1]=39; input[i+2]=59; input[i+3]=0;
    result=CharCase(input,value,i+3); if(result) return result;
  }
  input[0]=39; input[1]=92; input[5]=39; input[6]=59; input[7]=0;
  for(i=0;i<256;i++) for(j=0;j<2;j++) {
    input[2]='x'; if(j) input[2]='X';
    input[3]=hex[i>>4]; input[4]=hex[i&15];
    result=CharCase(input,i,7); if(result) return result;
  }
  input[0]=39; input[1]=92; input[3]=39; input[4]=59; input[5]=0;
  for(i=0;i<10;i++) {
    switch(i) {
      case 0: j='0'; k=0; break;
      case 1: j=39; k=39; break;
      case 2: j=96; k=96; break;
      case 3: j=34; k=34; break;
      case 4: j=92; k=92; break;
      case 5: j='d'; k=36; break;
      case 6: j='n'; k=10; break;
      case 7: j='r'; k=13; break;
      case 8: j='t'; k=9; break;
      case 9: j='q'; k=0x715C; break;
    }
    input[2]=j; result=CharCase(input,k,5); if(result) return result;
  }
  //Dollar doubling has no string dollar-counter side effect.
  input[1]=36; input[2]=36;
  result=CharCase(input,36,5); if(result) return result;
  input[2]=39; input[3]=59; input[4]=0;
  result=CharCase(input,36,4); if(result) return result;
  input[1]=10;
  result=CharCase(input,10,4,1); if(result) return result;
  //Zero/one-digit hex escapes replay the quote or following character.
  input[1]=92; input[2]='x'; input[3]=39; input[4]=59; input[5]=0;
  result=CharCase(input,0,5); if(result) return result;
  input[3]='A'; input[4]=39; input[5]=59; input[6]=0;
  result=CharCase(input,10,6); if(result) return result;
  return 0;
}
