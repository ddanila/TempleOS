CDirEntry *DTNode(U8 *name,U8 *data)
{
  CDirEntry *entry=CAlloc(sizeof(CDirEntry));
  entry->full_name=StrNew(name);
  entry->user_data=data;
  return entry;
}
I64 DTContract()
{
  I64 before=Fs->data_heap->used_u8s,mask=0;
  CDirEntry *a,*b,*c;
  U8 *data;
  DirEntryDel(NULL);DirEntryDel2(NULL);DirTreeDel(NULL);DirTreeDel2(NULL);
  if(Fs->data_heap->used_u8s==before)mask|=1;
  data=StrNew("preserved");a=DTNode("one",data);DirEntryDel(a);
  if(!StrCmp(data,"preserved"))mask|=2;
  Free(data);
  if(Fs->data_heap->used_u8s==before)mask|=4;
  a=DTNode("one",StrNew("data"));DirEntryDel2(a);
  if(Fs->data_heap->used_u8s==before)mask|=8;
  data=StrNew("tree-data");a=DTNode("a",data);b=DTNode("b",NULL);c=DTNode("c",NULL);
  a->next=b;a->sub=c;DirTreeDel(a);
  if(!StrCmp(data,"tree-data"))mask|=16;
  Free(data);
  if(Fs->data_heap->used_u8s==before)mask|=32;
  a=DTNode("a",StrNew("a-data"));b=DTNode("b",StrNew("b-data"));c=DTNode("c",StrNew("c-data"));
  a->next=b;a->sub=c;DirTreeDel2(a);
  if(Fs->data_heap->used_u8s==before)mask|=64;
  return mask;
}
