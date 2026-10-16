Bool GRExtCase(U8 *name,U8 *ext,U8 *expected)
{
  U8 *result=ExtDft(name,ext);
  Bool same=!StrCmp(result,expected);
  Free(result);return same;
}
I64 GRExtContract()
{
  I64 mask=0;
  if(GRExtCase("file","GR.Z","file.GR.Z"))mask|=1;
  if(GRExtCase("a.b/thing","GR.Z","a.b/thing"))mask|=2;
  if(GRExtCase("a./thing","GR.Z","a./thing.GR.Z"))mask|=4;
  if(GRExtCase("../thing","GR.Z","../thing.GR.Z"))mask|=8;
  if(GRExtCase("name.","GR.Z","name."))mask|=16;
  if(GRExtCase("","GR.Z",".GR.Z"))mask|=32;
  if(GRExtCase("file","","file."))mask|=64;
  if(GRExtCase("file.x.Z","GR.Z","file.x.Z"))mask|=128;
  return mask;
}
Bool GRPixels(CDC *dc,I64 high)
{
  I64 j;
  if(!dc || dc->width!=9 || dc->width_internal!=16 || dc->height!=32)return FALSE;
  for(j=0;j<512;j++)if(dc->body[j]!=((j&15)|high))return FALSE;
  return TRUE;
}
Bool GRDocBitmap(CDoc *doc,I64 high)
{
  I64 j;
  CDocBin *bin=doc->bin_head.next;
  U8 *data;
  if(bin==&doc->bin_head || bin->next!=&doc->bin_head || bin->size!=530 ||
      bin->num!=1 || bin->use_cnt!=1)return FALSE;
  data=bin->data;
  if(data[0]!=23 || data[529] || * (data+1)(I32 *) || * (data+5)(I32 *) ||
      * (data+9)(I32 *)!=9 || * (data+13)(I32 *)!=32)return FALSE;
  for(j=0;j<512;j++)if(data[17+j]!=((j&15)|high))return FALSE;
  return TRUE;
}
I64 GRReadContract(I64 drive)
{
  I64 i,high,size,mask=0;
  U8 *name,*raw,*data;
  CDC *dc;
  CDoc *doc,*old;
  CTask *owner;
  Bool reads=TRUE,ownership=TRUE,documents=TRUE;
  for(i=0;i<4;i++) {
    high=0;if(i==3)high=128;
    raw=MStrPrint("%c:/load%d.DATA",drive,i);data=FileRead(raw,&size);Free(raw);
    name=MStrPrint("%c:/read%d.GR",drive,i);
    if(FileWrite(name,data,size)<=0)reads=FALSE;
    Free(data);
    owner=NULL;if(i&1) {owner=Fs->parent_task;if(!owner || owner==Fs)ownership=FALSE;}
    dc=GRRead(name,owner);
    if(!GRPixels(dc,high))reads=FALSE;
    if(!owner)owner=Fs;
    if(!dc || dc->mem_task!=owner || dc->win_task!=owner)ownership=FALSE;
    DCDel(dc);
    doc=DocNew;DocGR(doc,name);
    if(!GRDocBitmap(doc,high))documents=FALSE;
    DocDel(doc);Free(name);
  }
  if(reads)mask|=1;if(ownership)mask|=2;if(documents)mask|=4;
  raw=MStrPrint("%c:/load3.DATA",drive);data=FileRead(raw,&size);Free(raw);
  name=MStrPrint("%c:/default.GR.Z",drive);
  if(FileWrite(name,data,size)<=0) {Free(name);Free(data);return mask;}
  Free(name);Free(data);
  name=MStrPrint("%c:/default",drive);
  dc=GRRead(name);if(GRPixels(dc,128))mask|=8;DCDel(dc);
  doc=DocNew;old=Fs->put_doc;Fs->put_doc=doc;
  DocGR(,name);Fs->put_doc=old;
  if(GRDocBitmap(doc,128))mask|=16;
  DocDel(doc);Free(name);
  name=MStrPrint("%c:/missing-graphic",drive);
  dc=GRRead(name);if(!dc)mask|=32;DCDel(dc);Free(name);
  return mask;
}
