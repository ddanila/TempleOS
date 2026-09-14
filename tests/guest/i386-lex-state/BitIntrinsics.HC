I64 BitIntrinsicsTest()
{
  U8 bytes[160],expected[160],*base;
  I64 bit,i,j,position,old,value,low,high,result,flags;
  U64 word,seed=0x123456789ABCDEF0;
  base=bytes+80;
  for(bit=-512;bit<512;bit++) {
    for(i=0;i<160;i++) bytes[i]=expected[i]=(i*73+bit*17)&255;
    position=80+(bit>>3);
    old=(expected[position]>>(bit&7))&1;
    flags=GetRFlags;
    result=Bt(base,bit);
    if(result!=old) return 85;
    result=Bts(base,bit);
    if(result!=old || !Bt(base,bit)) return 86;
    expected[position]|=1<<(bit&7);
    for(i=0;i<160;i++) if(bytes[i]!=expected[i]) return 87;
    if(!Bts(base,bit) || !Btr(base,bit) || Btr(base,bit)) return 88;
    expected[position]&=~(1<<(bit&7));
    for(i=0;i<160;i++) if(bytes[i]!=expected[i]) return 89;
    if(Btc(base,bit) || !Btc(base,bit)) return 90;
    if(LBts(base,bit) || !LBts(base,bit) || !LBtr(base,bit) || LBtr(base,bit)) return 91;
    if(LBtc(base,bit) || !LBtc(base,bit)) return 92;
    if((GetRFlags^flags)&0x200) return 93;
    for(i=0;i<160;i++) if(bytes[i]!=expected[i]) return 94;
  }
  //Unaligned bases and both sides of dword/qword boundaries.
  for(j=1;j<8;j++) {
    base=bytes+80+j;
    for(i=0;i<160;i++) bytes[i]=0;
    for(bit=-65;bit<=65;bit++) {
      if(Bts(base,bit) || !Bt(base,bit) || !Btr(base,bit)) return 95;
      if(LBts(base,bit) || !LBtc(base,bit) || LBtr(base,bit)) return 105;
    }
    for(i=0;i<160;i++) if(bytes[i]) return 96;
  }
  if(Bsf(0)!=-1 || Bsr(0)!=-1) return 97;
  for(i=0;i<64;i++) {
    word=1; word<<=i;
    if(Bsf(word)!=i || Bsr(word)!=i || Bsf(word|1)!=0 || Bsr(word|1)!=i) return 98;
  }
  for(j=0;j<512;j++) {
    seed=seed*6364136223846793005+1442695040888963407;
    low=-1; high=-1; word=seed;
    for(i=0;i<64;i++) if((word>>i)&1) { if(low<0) low=i; high=i; }
    if(Bsf(word)!=low || Bsr(word)!=high) return 99;
  }
  word=0; bit=32;
  value=Bts(&word,bit++);
  if(value || bit!=33 || word!=0x100000000) return 100;
  if(!Btr(&word,Bsf(word)) || word) return 101;
  word=0x8000000000000000;
  if(!Btc(&word,Bsr(word)) || word) return 102;
  return 0;
}
