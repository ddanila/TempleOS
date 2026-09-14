I64 HostStringTest()
{
  CCmpCtrl *cc; U8 *input;
  I64 i,j,*row,result=0;
  //Exercise the production Lex -> LexInStr wrapper, including embedded NUL.
  for(i=0;i<24;i++) {
    row=string_rows+i*7;
    input=CAlloc(row[1]+2); input[0]=34;
    for(j=0;j<row[1];j++) input[j+1]=string_sources[row[0]+j];
    cc=CmpCtrlNew(input);
    if(Lex(cc)!=TK_STR || cc->cur_str_len!=row[3]) result=128;
    if(!result) for(j=0;j<row[3];j++) if(cc->cur_str[j]!=string_expected[row[2]+j]) result=129;
    CmpCtrlDel(cc); if(result) return result;
  }
  input=CAlloc(324); input[0]=34;
  for(i=0;i<320;i++) input[i+1]='a'+i%26;
  input[321]=34;
  cc=CmpCtrlNew(input);
  if(Lex(cc)!=TK_STR || cc->cur_str_len!=321) result=130;
  if(!result) for(i=0;i<320;i++) if(cc->cur_str[i]!='a'+i%26) result=131;
  if(!result && cc->cur_str[320]) result=132;
  CmpCtrlDel(cc);
  return result;
}
