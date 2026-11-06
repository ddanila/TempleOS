I64 nk_notes[8]={I64_MIN,-13,-1,0,2,3,12,I64_MAX};
I64 nk_octaves[8]={I64_MIN,I64_MAX,-1,0,4,10,I64_MAX,I64_MIN};
U0 NKLog(U8 *s) {while(*s)OutU8(0xE9,*s++);}
U0 NKCheck()
{
  U8 values[1482],*s;I64 i,j,k=0;
  for(i=-128;i<128;i++) {
    values[k++]=Ona2Note(i);
    values[k++]=Ona2Octave(i);
  }
  for(i=-12;i<=24;i++)
    for(j=-12;j<=12;j++)values[k++]=Note2Ona(i,j);
  for(i=-12;i<=24;i++)values[k++]=Note2Ona(i);
  for(i=0;i<8;i++)values[k++]=Note2Ona(nk_notes[i],nk_octaves[i]);
  if(k!=sizeof(values))throw('NoteVec',TRUE);
  s=MStrPrint("EXPORT notes.bin %X %X\n",values,sizeof(values));NKLog(s);Free(s);
  NKLog("NOTE CONVERSION DONE\n");Sleep(1000);
}
