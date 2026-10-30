I64 KeyMapSortContract()
{
  U8 a[64],b[64],c[64],d[64],e[64],f[64];
  I64 slots[9],*entries=&slots[1],i,j,mask=0;Bool ordered=TRUE,found;
  MemSet(a,0,64);MemSet(b,0,64);MemSet(c,0,64);MemSet(d,0,64);MemSet(e,0,64);MemSet(f,0,64);
  StrCpy(a,"SHIFT Zebra");StrCpy(b,"ALPHA");StrCpy(c,"SHIFT Alpha");
  StrCpy(d,"BETA");StrCpy(e,"Zebra");StrCpy(f,"CTRL SHIFT Q");
  slots[0]=0x123456789ABCDEF;slots[8]=0x23456789ABCDEF0;
  entries[0]=(a+0)(I64);entries[1]=(b+0)(I64);entries[2]=(c+0)(I64);entries[3]=0;
  entries[4]=(d+0)(I64);entries[5]=(e+0)(I64);entries[6]=(f+0)(I64);
  QSortI64(entries,7,&KMCompare);
  for(i=0;i<6;i++)if(KMCompare(entries[i](U8 *),entries[i+1](U8 *))>0)ordered=FALSE;
  if(ordered && !entries[0])mask|=1;
  if(slots[0]==0x123456789ABCDEF && slots[8]==0x23456789ABCDEF0)mask|=2;
  found=TRUE;
  for(i=0;i<7;i++)for(j=i+1;j<7;j++)if(entries[i]==entries[j])found=FALSE;
  for(i=0;i<7;i++)if(entries[i] && entries[i]!=(a+0)(I64) && entries[i]!=(b+0)(I64) && entries[i]!=(c+0)(I64) && entries[i]!=(d+0)(I64) && entries[i]!=(e+0)(I64) && entries[i]!=(f+0)(I64))found=FALSE;
  if(found)mask|=4;
  return mask;
}
