U0 HSLog(U8 *s){while(*s)OutU8(0xE9,*s++);}
CHashGeneric *HSNode(U8 *name,I64 value)
{
  CHashGeneric *node=CAlloc(sizeof(CHashGeneric));
  node->str=StrNew(name);node->type=HTT_KEYWORD;node->user_data0=value;return node;
}
U0 HSCheck()
{
  I64 mask=0,used=Fs->data_heap->used_u8s,*result;U8 *s;
  CHashTable *parent=HashTableNew(1),*child=HashTableNew(1);
  CHashGeneric *first=HSNode("Duplicate",0x1122334455667788),*second=HSNode("Duplicate",2);
  CHashGeneric *outer=HSNode("Duplicate",3),*only_parent=HSNode("ParentOnly",4);
  CHashClass *other=CAlloc(sizeof(CHashClass));
  other->str=StrNew("Duplicate");other->type=HTT_CLASS;other->raw_type=RT_I64;other->size=8;
  child->next=parent;HashAdd(outer,parent);HashAdd(only_parent,parent);
  HashAdd(second,child);HashAdd(other,child);HashAdd(first,child);
  if(!HashSingleTableFind("Missing",child,HTT_KEYWORD))mask|=1;
  if(HashSingleTableFind("Duplicate",child,HTT_KEYWORD)==first)mask|=2;
  if(HashSingleTableFind("Duplicate",child,HTT_KEYWORD,2)==second)mask|=4;
  if(HashSingleTableFind("Duplicate",child,HTT_CLASS)==other)mask|=8;
  if(!HashSingleTableFind("ParentOnly",child,HTT_KEYWORD) &&
      HashFind("ParentOnly",child,HTT_KEYWORD)==only_parent)mask|=16;
  if(!HashSingleTableFind("Duplicate",child,HTT_KEYWORD,3) &&
      HashFind("Duplicate",child,HTT_KEYWORD,3)==outer)mask|=32;
  if(!HashSingleTableFind("Duplicate",child,HTT_KEYWORD,0) &&
      !HashSingleTableFind("Duplicate",child,HTT_KEYWORD,-1) &&
      !HashSingleTableFind("Duplicate",child,HTT_KEYWORD,0x100000001) &&
      !HashSingleTableFind("Duplicate",child,0))mask|=64;
  if(first->use_cnt==1 && second->use_cnt==1 && other->use_cnt==1 &&
      outer->use_cnt==1 && only_parent->use_cnt==1)mask|=128;
  first->use_cnt=0xFFFFFFFF;
  if(HashSingleTableFind("Duplicate",child,HTT_KEYWORD)==first && !first->use_cnt &&
      first->type==HTT_KEYWORD && first->next==other &&
      first->user_data0==0x1122334455667788)mask|=256;
  HashTableDel(child);HashTableDel(parent);
  if(Fs->data_heap->used_u8s==used)mask|=512;
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT hash-single-mask.bin %X 8\n",result);HSLog(s);Free(s);
  HSLog("HASH SINGLE DONE\n");Sleep(1000);
}
HSCheck;
