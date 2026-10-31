//Mirror the native pool prefix solely to report its backing-region count.
class CBibleProfilePool:CBlkPool {
  U8 *regions;
  U32 size,signature,region_count,growing;
};
U0 BPRegions(I64 lines)
{
  CBibleProfilePool *pool=Fs->data_heap->bp;
  U8 *text=MStrPrint("BIBLE REGIONS %d %d\n",lines,pool->region_count),*p=text;
  while(*p)OutU8(0xE9,*p++);
  Free(text);
}
U0 BPMark(U8 *phase,I64 lines)
{
  U8 *text=MStrPrint("BIBLE PROFILE %d %s\n",lines,phase),*p=text;
  while(*p)OutU8(0xE9,*p++);
  Free(text);
}
I64 BibleProfile(U8 *name,I64 lines)
{
  U8 *data;I64 size;CDoc *doc;
  BPMark("read-begin",lines);
  data=FileRead(name,&size);
  if(!data || !size)throw('BPRead',TRUE);
  BPMark("read-end",lines);
  doc=DocNew;doc->flags|=DOCF_PLAIN_TEXT|DOCF_NO_CURSOR;
  BPMark("put-begin",lines);
  DocPutS(doc,data);
  BPMark("put-end",lines);
  BPRegions(lines);
  DocTop(doc);
  BPMark("layout-end",lines);
  if(!DocFind(doc,297,"1:1"))throw('BPFind',TRUE);
  BPMark("find-end",lines);
  DocDel(doc);Free(data);
  BPMark("free-end",lines);
  return 1;
}

I64 BibleProfileAll()
{
  if(!BibleProfile("C:/Probe/Bible400.TXT",400))return FALSE;
  if(!BibleProfile("C:/Probe/Bible800.TXT",800))return FALSE;
  if(!BibleProfile("C:/Probe/Bible1200.TXT",1200))return FALSE;
  if(!BibleProfile("C:/Probe/Bible1600.TXT",1600))return FALSE;
  return TRUE;
}

I64 BibleProfileLarge()
{
  if(!BibleProfile("C:/Probe/Bible1600.TXT",1600))return FALSE;
  if(!BibleProfile("C:/Probe/Bible3200.TXT",3200))return FALSE;
  if(!BibleProfile("C:/Probe/Bible4800.TXT",4800))return FALSE;
  if(!BibleProfile("C:/Probe/Bible6400.TXT",6400))return FALSE;
  return TRUE;
}

I64 BibleProfileMedium()
{
  if(!BibleProfile("C:/Probe/Bible1600.TXT",1600))return FALSE;
  if(!BibleProfile("C:/Probe/Bible3200.TXT",3200))return FALSE;
  return TRUE;
}
