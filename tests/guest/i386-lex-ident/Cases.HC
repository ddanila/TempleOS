U0 IdentSeed(CCmpCtrl *cc,CLexFile *file,U8 *input,I64 flags=0)
{
  U8 *bytes=cc; I64 i; U32 *bitmap=char_bmp_alpha_numeric;
  for(i=0;i<sizeof(CCmpCtrl);i++) bytes[i]=0;
  bytes=file; for(i=0;i<sizeof(CLexFile);i++) bytes[i]=0;
  if(flags&CCF_KEEP_AT_SIGN) bitmap=char_bmp_alpha_numeric_no_at;
  CmpCtrlSeed(cc,flags|CCF_DONT_FREE_BUF,0,bitmap);
  LexFileSeed(file,input); cc->lex_include_stk=file; cc->cur_buf_ptr=input;
}
I64 IdentCase(U8 *input,U8 *expected,I64 length,I64 flags=0)
{
  CCmpCtrl cc; CLexFile file; U8 output[146]; I64 i,lines=0;
  for(i=0;i<146;i++) output[i]=0xA5;
  IdentSeed(&cc,&file,input,flags);
  if(IdentToken(&cc,output+1,&lines)!=TK_IDENT || cc.cur_str_len!=length+1 ||
      cc.cur_buf_ptr!=input+length+1 || cc.last_U16!=input[length] ||
      !(cc.flags&CCF_USE_LAST_U16) || cc.hash_entry || cc.local_var_entry) return 100;
  for(i=0;i<length;i++) if(output[i+1]!=expected[i]) return 101;
  if(output[length+1]) return 102;
  if(output[0]!=0xA5) return 103;
  for(i=length+2;i<146;i++) if(output[i]!=0xA5) return 104;
  return 0;
}
I64 IdentTest()
{
  U8 input[146],expected[146]; I64 i,j,result;
  for(i=1;i<144;i++) {
    for(j=0;j<i;j++) input[j]=expected[j]='a'+j%26;
    input[i]=59; input[i+1]=0;
    result=IdentCase(input,expected,i); if(result) return result;
  }
  for(i=128;i<256;i++) {
    input[0]=expected[0]=i; input[1]=expected[1]=i;
    input[2]=expected[2]='9'; input[3]=expected[3]='_'; input[4]=expected[4]='@';
    input[5]=59; input[6]=0;
    result=IdentCase(input,expected,5); if(result) return result;
  }
  for(i=1;i<=3;i++) {
    input[0]=i; input[1]='a'; input[2]=i; input[3]=59; input[4]=0;
    if(i==1) expected[0]='>'; if(i==2) expected[0]='<'; if(i==3) expected[0]='=';
    expected[1]='a'; expected[2]=expected[0];
    result=IdentCase(input,expected,3); if(result) return result;
  }
  input[0]=expected[0]='@'; input[1]='a'; expected[1]='a'; input[2]=59; input[3]=0;
  result=IdentCase(input,expected,2); if(result) return result;
  input[0]=expected[0]='a'; input[1]='@'; input[2]='b'; input[3]=0;
  result=IdentCase(input,expected,1,CCF_KEEP_AT_SIGN); if(result) return result;
  return 0;
}
