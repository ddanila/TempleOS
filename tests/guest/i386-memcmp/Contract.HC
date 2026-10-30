I64 MemCmpContract()
{
  U8 a[32],b[32];I64 i,mask=0;Bool ok=TRUE;
  for(i=0;i<32;i++)a[i]=b[i]=(i*47+3)&255;
  if(MemCmp(a,b,32)==0 && MemCmp(NULL,NULL,0)==0)mask|=1;
  b[0]=a[0]+1;b[31]=0;
  if(MemCmp(a,b,32)==-1 && MemCmp(b,a,32)==1)mask|=2;
  b[0]=a[0];b[31]=a[31]+1;
  if(MemCmp(a,b,31)==0 && MemCmp(a,b,32)==-1)mask|=4;
  a[7]=0x80;b[7]=0x7F;
  if(MemCmp(a,b,8)==1 && MemCmp(b,a,8)==-1)mask|=8;
  for(i=0;i<32;i++) {b[i]=a[i];if(MemCmp(a,b,i+1))ok=FALSE;}
  if(ok)mask|=16;
  return mask;
}
