//Same public table/alias/parent/ownership corpus on original x64 and native heaps.
I64 HashTableCheck(CHashTable *(*create)(I64 size,CTask *task),
  U0 (*destroy)(CHashTable *table),I64 (*insert)(U8 *list,I64 type,CHashTable *table),
  CHash *(*find)(U8 *name,CHashTable *table,I64 mask,I64 instance),
  CHeapCtrl *(*owner)(U8 *allocation))
{
  CHashTable *parent=(*create)(8,0),*child=(*create)(1,0);
  CHashGeneric *entry;
  I64 result=0,i;
  if(parent->mask!=7 || child->mask || parent->next || child->next ||
      parent->locked_flags || child->locked_flags) result=-1;
  for(i=0;i<8;i++) if(parent->body[i]) result=-2;
  if(child->body[0] || (*owner)(parent)!=Fs->data_heap ||
      (*owner)(parent->body)!=Fs->data_heap) result=-3;
  child->next=parent;
  if((*insert)("root\0Common\0",HTT_KEYWORD,parent)!=2 ||
      (*insert)("zero\0@alias\0one\0@uno\0Common\0",HTT_KEYWORD,child)!=3) result=-4;
  entry=(*find)("alias",child,HTT_KEYWORD,1);
  if(!entry || entry->user_data0 || (*owner)(entry)!=Fs->data_heap ||
      (*owner)(entry->str)!=Fs->data_heap) result=-5;
  entry=(*find)("uno",child,HTT_KEYWORD,1);
  if(!entry || entry->user_data0!=1) result=-6;
  entry=(*find)("Common",child,HTT_KEYWORD,1);
  if(!entry || entry->user_data0!=2) result=-7;
  entry=(*find)("Common",child,HTT_KEYWORD,2);
  if(!entry || entry->user_data0!=1 || (*find)("missing",child,HTT_KEYWORD,1) ||
      (*find)("zero",child,HTT_FRAME_PTR,1)) result=-8;
  if((*insert)(0,HTT_KEYWORD,child) || (*insert)("",HTT_KEYWORD,child)) result=-9;
  (*destroy)(child); (*destroy)(0);
  entry=(*find)("root",parent,HTT_KEYWORD,1);
  if(!entry || entry->user_data0) result=-10;
  (*destroy)(parent);
  if(result) return result;
  return 10;
}
