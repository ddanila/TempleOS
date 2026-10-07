//Integer-limb Payne-Hanek reduction; model: tools/i386_trig_reduction.py.
U32 i386_trig_reciprocal[52]={
  0xDCE8092A,0x19C367CD,0x8C6B47C4,0x60E27BC0,
  0xCA73A8C9,0x06061556,0x4D732731,0x8DFFD880,
  0x14A06840,0x6599855F,0x5EE61B08,0xA9E39161,
  0x9AF4361D,0xF0CFBC20,0xFC7B6BAB,0x56033046,
  0x1F8D5D08,0x6BFB5FB1,0x8A5292EA,0x3D0739F7,
  0xEBE5F17B,0x7527BAC7,0x9E5FEA2D,0x4F463F66,
  0x27CB09B7,0x6D367ECF,0x5A0A6D1F,0xEF2F118B,
  0xDE05980F,0x1FF897FF,0xBDF9283B,0x9C845F8B,
  0x835339F4,0x3991D639,0xB45F7E41,0xE99C7026,
  0x2EBB4484,0xE88235F5,0xB129A73E,0xFE1DEB1C,
  0x09D1921C,0x06492EEA,0x424DD2E0,0xB7246E3A,
  0xDEBBC561,0xFE5163AB,0x3C439041,0xDB629599,
  0xF534DDC0,0xFC2757D1,0x4E441529,0xA2F9836E
};
I64 I386TrigBit(U32 *words,I64 bit)
{
  if(bit<0 || bit>=1728)return 0;
  return words[bit/32]>>(bit%32)&1;
}
U0 I386TrigTruncate(U32 *words,I64 bits)
{
  I64 i,left;
  for(i=0;i<54;i++) {
    left=bits-i*32;
    if(left<=0)words[i]=0;
    else if(left<32)words[i]&=(1(U64)<<left)-1;
  }
}
F64 I386TrigScale(F64 value,I64 power)
{//Reducer powers are <= -52 and >= -1770; split subnormal scaling.
  U64 factor;
  if(power< -1022) {value*=0x0010000000000000(F64);power+=1022;}
  factor=(power+1023)(U64)<<52;
  return value*factor(F64);
}
F64 I386TrigRound(F64 value)
{//An ABI boundary rounds to binary64 even in the original x87 host compiler.
  return value;
}
I64 I386TrigReduce(F64 x,F64 *head,F64 *tail)
{//Finite input -> quadrant mod four and centered head/tail remainder.
  U64 bits=x(U64),magnitude=bits&0x7FFFFFFFFFFFFFFF,
    significand,word,total,carry,chunk,multiplicand;
  U32 product[54],fraction[54];
  I64 i,j,point,quadrant,round_up,top,offset,index;
  F64 high,low,pi_high=0x3FF921FB54442D18(F64),
    pi_low=0x3C91A62633145C07(F64),splitter=134217729.0,
    split,a_hi,a_lo,b_hi,b_lo,result,error,remainder;
  *head=x;*tail=0;
  if(magnitude>=0x7FF0000000000000)return -1;
  if(magnitude<=0x3FE921FB54442D18)return 0;
  significand=(magnitude&0xFFFFFFFFFFFFF)|0x10000000000000;
  point=1664-((magnitude>>52)(I64)-1075);
  for(i=0;i<54;i++)product[i]=0;
  for(j=0;j<2;j++) {
    word=significand>>(j*32)&0xFFFFFFFF;
    carry=0;
    for(i=0;i<52;i++) {
      multiplicand=i386_trig_reciprocal[i];
      total=multiplicand*word+product[i+j]+carry;
      product[i+j]=total;carry=total>>32;
    }
    product[52+j]=carry;
  }
  quadrant=I386TrigBit(product,point)|I386TrigBit(product,point+1)<<1;
  round_up=I386TrigBit(product,point-1);
  for(i=0;i<54;i++)fraction[i]=product[i];
  I386TrigTruncate(fraction,point);
  if(round_up) {
    quadrant=(quadrant+1)&3;carry=1;
    for(i=0;i<54;i++) {
      total=0xFFFFFFFF(U64)-fraction[i]+carry;
      fraction[i]=total;carry=total>>32;
    }
    I386TrigTruncate(fraction,point);
  }
  top=1727;
  while(top>=0 && !I386TrigBit(fraction,top))top--;
  high=0;low=0;
  if(top>=0)for(offset=0;offset<=53;offset+=53) {
    chunk=0;
    for(index=0;index<53;index++)
      chunk=chunk<<1|I386TrigBit(fraction,top-offset-index);
    result=I386TrigScale(ToF64(chunk),top-offset-52-point);
    if(!offset)high=result;else low=result;
  }
  result=I386TrigRound(high*pi_high);
  split=I386TrigRound(splitter*high);
  a_hi=I386TrigRound(split-I386TrigRound(split-high));
  a_lo=I386TrigRound(high-a_hi);
  split=I386TrigRound(splitter*pi_high);
  b_hi=I386TrigRound(split-I386TrigRound(split-pi_high));
  b_lo=I386TrigRound(pi_high-b_hi);
  error=I386TrigRound(I386TrigRound(a_hi*b_hi)-result);
  error=I386TrigRound(error+I386TrigRound(a_hi*b_lo));
  error=I386TrigRound(error+I386TrigRound(a_lo*b_hi));
  error=I386TrigRound(error+I386TrigRound(a_lo*b_lo));
  error=I386TrigRound(error+I386TrigRound(I386TrigRound(high*pi_low)+I386TrigRound(low*pi_high)));
  remainder=I386TrigRound(result+error);
  *tail=I386TrigRound(I386TrigRound(result-remainder)+error);
  *head=remainder;
  if(round_up) {*head=-*head;*tail=-*tail;}
  if(bits>>63) {quadrant=(-quadrant)&3;*head=-*head;*tail=-*tail;}
  return quadrant;
}
