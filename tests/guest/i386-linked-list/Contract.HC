I64 ll_sizes[4]={32,55,96,139};
U0 LLLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 LLCheck()
{
  I64 mask=0,used=Fs->data_heap->used_u8s,with_source,i,j;
  I64 *result;
  U8 **source[4],**copies[4],**copy,**node,*s;
  Bool payload=TRUE,independent=TRUE;
  if(!LinkedLstCopy(NULL))mask|=1;
  LinkedLstDel(NULL);
  if(Fs->data_heap->used_u8s==used)mask|=2;
  for(i=0;i<4;i++) {
    source[i]=MAlloc(ll_sizes[i]);
    for(j=0;j<MSize(source[i]);j++)source[i](U8 *)[j]=i*31+j*17;
    *source[i]=NULL;
    if(i)*source[i-1]=source[i];
  }
  with_source=Fs->data_heap->used_u8s;
  copy=node=LinkedLstCopy(source[0]);
  for(i=0;i<4 && node;i++){copies[i]=node;node=*node;}
  if(i==4 && !node)mask|=4;
  for(i=0;i<4;i++) {
    if(MSize(copies[i])!=MSize(source[i]) ||
        MemCmp(copies[i](U8 *)+sizeof(U8 *),source[i](U8 *)+sizeof(U8 *),
        MSize(source[i])-sizeof(U8 *)))payload=FALSE;
    if(copies[i]==source[i])independent=FALSE;
    if(i<3 && *source[i]!=source[i+1] || i==3 && *source[i])independent=FALSE;
  }
  if(payload)mask|=8;
  if(independent)mask|=16;
  j=sizeof(U8 *)+3;
  copies[1](U8 *)[j]^=255;
  node=*copies[1];*copies[1]=NULL;
  if(copies[1](U8 *)[j]!=(source[1](U8 *)[j]) && *source[1]==source[2])mask|=32;
  *copies[1]=node;
  LinkedLstDel(copy);
  if(Fs->data_heap->used_u8s==with_source)mask|=64;
  copy=LinkedLstCopy(source[0],Fs);
  if(copy && copy!=source[0] && *copy!=*source[0] &&
      !MemCmp(copy(U8 *)+sizeof(U8 *),source[0](U8 *)+sizeof(U8 *),
      MSize(source[0])-sizeof(U8 *)))mask|=128;
  LinkedLstDel(copy);LinkedLstDel(source[0]);
  if(Fs->data_heap->used_u8s==used)mask|=256;
  node=MAlloc(40);MemSet(node,0x5A,MSize(node));*node=NULL;
  copy=LinkedLstCopy(node);
  if(copy && !*copy && copy!=node && MSize(copy)==MSize(node) &&
      !MemCmp(copy(U8 *)+sizeof(U8 *),node(U8 *)+sizeof(U8 *),
      MSize(node)-sizeof(U8 *)))mask|=512;
  LinkedLstDel(copy);LinkedLstDel(node);
  if(Fs->data_heap->used_u8s!=used)mask&=~512;
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT linked-list-mask.bin %X 8\n",result);LLLog(s);Free(s);
  LLLog("LINKED LIST DONE\n");Sleep(1000);
}
LLCheck;
