I64 fill_times[2];
U0 FillBench()
{
  I64 size=640*480,i,pass;
  U8 *raw=MAlloc(size+2),*buffer=raw+1,*end;
  U8 line[100],*p=line;
  if(!raw)throw('FillMem',TRUE);
  raw[0]=13;raw[size+1]=29;
  if(MemSet(NULL,1,0) || MemSet(buffer,1,-1)!=raw)
    throw('FillZero',TRUE);
  fill_times[0]=ToI64(tS*1000);
  for(pass=0;pass<5;pass++) {
    end=MemSet(buffer,0x1A3+pass,size);
    if(end!=buffer+size)throw('FillEnd',TRUE);
  }
  fill_times[1]=ToI64(tS*1000);
  if(raw[0]!=13 || raw[size+1]!=29)throw('FillEdge',TRUE);
  for(i=0;i<size;i++)if(buffer[i]!=0xA7)throw('FillData',TRUE);
  Free(raw);
  StrPrint(line,"EXPORT fill.bin %X 10\n",fill_times);
  while(*p)OutU8(0xE9,*p++);
}
