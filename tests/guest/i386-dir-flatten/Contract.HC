CDirEntry *DFNode(U8 *name,Bool dir)
{
  CDirEntry *e=CAlloc(sizeof(CDirEntry));
  e->full_name=StrNew(name);StrCpy(e->name,name);
  if(dir)e->attr|=0x10;
  return e;
}
CDirEntry *DFTree()
{
  CDirEntry *a=DFNode("A",TRUE),*b=DFNode("B",FALSE),*c=DFNode("C",FALSE),*d=DFNode("D",TRUE),*e=DFNode("E",FALSE);
  a->next=b;a->sub=c;c->next=d;d->sub=e;return a;
}
Bool DFCheck(CDirEntry *node,U8 *expected)
{
  while(*expected && node) {
    if(node->name[0]!=*expected || node->name[1] || node->sub)return FALSE;
    expected++;node=node->next;
  }
  return !*expected && !node;
}
I64 DFContract()
{
  I64 before=Fs->data_heap->used_u8s,mask=0;
  CDirEntry *a,*flat,**tail;
  flat=NULL;tail=DirFilesFlatten(NULL,&flat,0);
  if(!flat && tail==&flat)mask|=1;
  a=DFTree;flat=NULL;tail=DirFilesFlatten(a,&flat,0);
  if(DFCheck(flat,"ACDEB") && tail && !*tail)mask|=2;
  DirTreeDel(flat);
  if(Fs->data_heap->used_u8s==before)mask|=4;
  a=DFTree;flat=NULL;tail=DirFilesFlatten(a,&flat,0x800);
  if(DFCheck(flat,"CEB") && tail && !*tail)mask|=8;
  DirTreeDel(flat);
  if(Fs->data_heap->used_u8s==before)mask|=16;
  return mask;
}
