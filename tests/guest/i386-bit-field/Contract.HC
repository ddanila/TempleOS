U0 BFReport(U8 *s){while(*s)OutU8(0xE9,*s++);}
#define BIT_FIELD_EXTRACT_NAME PortableBFieldExtU32
#include "/Kernel/BitFieldExtractCore.HC"
U32 BFOracle(U8 *data,I64 start,I64 size)
{
  U32 result=0;I64 i;
  size&=63;if(size>32)size=32;
  for(i=0;i<size;i++)if(data[(start+i)/8]&(1<<((start+i)%8)))result|=1<<i;
  return result;
}
I64 JRContract(I64 unused)
{
  U8 data[32];I64 i,start,size,pattern,original_size;U32 expected,original,portable;I64 mask=0;
  for(pattern=0;pattern<6;pattern++) {
    for(i=0;i<32;i++) {
      switch(pattern) {
        case 0:data[i]=0;break;
        case 1:data[i]=255;break;
        case 2:data[i]=0x55;break;
        case 3:data[i]=0xAA;break;
        case 4:data[i]=(i*73+19)&255;break;
        case 5:data[i]=1<<(i%8);break;
      }
    }
    for(start=0;start<128;start++)for(size=0;size<=128;size++) {
      expected=BFOracle(data,start,size);
      original_size=size&63;if(original_size>32)original_size=32;
      original=BFieldExtU32(data,start,original_size);portable=PortableBFieldExtU32(data,start,size);
      if(original!=expected || portable!=expected) {
        U8 *line=MStrPrint("OBS bit mismatch %d %d %d %X %X %X\n",pattern,start,size,expected,original,portable);BFReport(line);Free(line);return mask;
      }
    }
    mask|=1<<pattern;
  }
  return mask;
}
