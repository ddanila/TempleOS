I64 DocBasicRoundTripCheck(U8 *(*save)(CDoc *doc,I64 *size))
{
  CDoc *source=DocNew("C:/RoundTrip.DD",Fs),*loaded;
  U8 *first,*second;
  I64 first_size,second_size,result=5,index;
  DocPutKey(source,'a'); DocPutKey(source,'b'); DocPutKey(source,'c');
  DocPutKey(source,0,0x4B); DocPutKey(source,0,0x4B); DocPutKey(source,'Z');
  first=(*save)(source,&first_size);
  loaded=DocNew("C:/RoundTrip.DD",Fs);
  if(!DocBasicLoadCore(loaded,first,first_size)) result=-1;
  second=(*save)(loaded,&second_size);
  if(first_size!=5 || second_size!=first_size) result=-2;
  else for(index=0;index<=first_size;index++)
    if(first[index]!=second[index]) result=-3;
  if(!DocBasicTextEqu(loaded,"aZbc")) result=-4;
  Free(first); Free(second); DocDel(source); DocDel(loaded);
  return result;
}
