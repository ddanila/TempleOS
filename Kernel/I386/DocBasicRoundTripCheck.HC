I64 DocBasicRoundTripCheck(U8 *(*save)(CDoc *doc,I64 *size))
{
  CDoc *source=DocNew("C:/RoundTrip.DD",Fs),*loaded;
  U8 *first,*second;
  I64 first_size,second_size,result=6,index;
  DocPutKey(source,'a'); DocPutKey(source,'b'); DocPutKey(source,'c');
  DocPutKey(source,0,0x4B); DocPutKey(source,0,0x4B); DocPutKey(source,'Z');
  DocPutKey(source,'\t',0x0F);
  first=(*save)(source,&first_size);
  loaded=DocNew("C:/RoundTrip.DD",Fs);
  if(!DocBasicLoadCore(loaded,first,first_size)) result=-1;
  second=(*save)(loaded,&second_size);
  if(first_size!=6 || second_size!=first_size) result=-2;
  else for(index=0;index<=first_size;index++)
    if(first[index]!=second[index]) result=-3;
  if(first[0]!='a' || first[1]!='Z' || first[2]!='\t' || first[3]!=CH_CURSOR ||
      first[4]!='b' || first[5]!='c') result=-4;
  Free(first); Free(second); DocDel(source); DocDel(loaded);
  return result;
}
