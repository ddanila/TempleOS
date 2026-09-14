U8 adjacent_strings[10]={34,36,97,34,34,36,98,34,59,0};
I64 full_string_lengths[10]={0,1,142,143,144,285,286,287,600,2048};
I64 StringTokenTest()
{
  CCmpCtrl cc; CLexFile file; U8 input[2052]; I64 i,j,*r,lines,length,last;
  for(i=0;i<24;i++) {
    r=string_rows+i*7; input[0]=34;
    for(j=0;j<r[1];j++) input[j+1]=string_sources[r[0]+j];
    input[r[1]+1]=0; lines=0; StringControlSeed(&cc,&file,input);
    last=0; if(r[1] && string_sources[r[0]+r[1]-1]==33) last=33;
    if(FullString(&cc,&lines)!=TK_STR || cc.cur_str_len!=r[3] || cc.flags&CCF_IN_QUOTES ||
        !(cc.flags&CCF_USE_LAST_U16) || cc.cur_buf_ptr!=input+r[1]+1 || cc.last_U16!=last ||
        cc.dollar_cnt!=r[5] || file.line_num!=r[6]+1) return 160;
    for(j=0;j<r[3];j++) if(cc.cur_str[j]!=string_expected[r[2]+j]) return 161;
    if(!FullStringFree(&cc)) return 162;
  }
  for(i=0;i<10;i++) {
    length=full_string_lengths[i]; input[0]=34;
    for(j=0;j<length;j++) input[j+1]='a'+j%26;
    input[length+1]=34; input[length+2]=59; input[length+3]=0;
    lines=0; StringControlSeed(&cc,&file,input);
    if(FullString(&cc,&lines)!=TK_STR || cc.cur_str_len!=length+1 || cc.cur_str[length] ||
        cc.cur_buf_ptr!=input+length+3 || cc.last_U16!=59) return 163;
    for(j=0;j<length;j++) if(cc.cur_str[j]!='a'+j%26) return 164;
    if(!FullStringFree(&cc)) return 165;
  }
  lines=0; StringControlSeed(&cc,&file,adjacent_strings);
  if(FullString(&cc,&lines)!=TK_STR || cc.cur_str_len!=3 || cc.dollar_cnt!=1 ||
      cc.cur_str[0]!=36 || cc.cur_str[1]!='a' || cc.cur_str[2]) return 166;
  if(FullString(&cc,&lines)!=TK_STR || cc.cur_str_len!=3 || cc.dollar_cnt ||
      cc.cur_str[0]!=36 || cc.cur_str[1]!='b' || cc.cur_str[2] || !FullStringFree(&cc)) return 167;
  return 0;
}
