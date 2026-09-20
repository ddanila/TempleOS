//One corpus for original x64 exports and native callable public bindings.
I64 BitEquCheck(Bool (*plain)(U8 *field,I64 bit,Bool val),
  Bool (*locked)(U8 *field,I64 bit,Bool val))
{
  U8 bytes[32],expected[32],*base;
  I64 mode,n,round,i,bit,logical,index,mask,checks=0;
  Bool val,old,actual;
  for(mode=0;mode<2;mode++) for(n=0;n<14;n++) for(round=0;round<6;round++) {
    bit=0;
    switch(n) {
      case 0: bit=-65; break;
      case 1: bit=-33; break;
      case 2: bit=-1; break;
      case 3: bit=0; break;
      case 4: bit=1; break;
      case 5: bit=7; break;
      case 6: bit=8; break;
      case 7: bit=31; break;
      case 8: bit=32; break;
      case 9: bit=63; break;
      case 10: bit=64; break;
      case 11: bit=65; break;
    }
    logical=bit; base=bytes+16;
    //Bias the base in the opposite direction so wide offsets still address our
    //array on both targets. Native arithmetic wraps only at the pointer width.
    if(n==12) { logical=5; bit=0x100000005; base-=0x20000000; }
    if(n==13) { logical=5; bit=-0xFFFFFFFB; base+=0x20000000; }
    val=0;
    switch(round) {
      case 0: val=0; break;
      case 1: val=1; break;
      case 2: val=2; break;
      case 3: val=-1; break;
      case 4: val=127; break;
      case 5: val=-128; break;
    }
    for(i=0;i<32;i++) { bytes[i]=i*17+round*3; expected[i]=bytes[i]; }
    index=(128+logical)/8; mask=1<<(logical&7);
    old=(expected[index]&mask)!=0;
    if(val) expected[index]|=mask;
    else expected[index]&=~mask;
    if(mode) actual=(*locked)(base,bit,val);
    else actual=(*plain)(base,bit,val);
    if(actual!=old) return -1;
    for(i=0;i<32;i++) if(bytes[i]!=expected[i]) return -2;
    if(mode) actual=(*locked)(base,bit,val);
    else actual=(*plain)(base,bit,val);
    if(actual!=(val!=0)) return -3;
    if(mode) actual=(*locked)(base,bit,!val);
    else actual=(*plain)(base,bit,!val);
    if(actual!=(val!=0)) return -4;
    expected[index]^=mask;
    for(i=0;i<32;i++) if(bytes[i]!=expected[i]) return -5;
    checks++;
  }
  return checks;
}
