I64 BFOrContract()
{
  U8 actual[32],expected[32];U32 pattern;I64 group,bit,i,j,mask=0;Bool ok;
  for(group=0;group<4;group++) {
    ok=TRUE;
    for(bit=0;bit<128;bit++) {
      for(i=0;i<32;i++)actual[i]=expected[i]=(i*37+bit*13+group*53)&255;
      switch(group) {
        case 0:pattern=0;break;
        case 1:pattern=0xFFFFFFFF;break;
        case 2:pattern=0x80000001;break;
        case 3:pattern=0xA55A3CC3;break;
      }
      BFieldOrU32(actual,bit,pattern);
      for(i=0;i<32;i++)if(pattern&(1<<i)) {
        j=bit+i;expected[j>>3]|=1<<(j&7);
      }
      for(i=0;i<32;i++)if(actual[i]!=expected[i])ok=FALSE;
    }
    if(ok)mask|=1<<group;
  }
  return mask;
}
