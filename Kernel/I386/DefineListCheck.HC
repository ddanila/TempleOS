//Exercise public list ownership with a caller buffer that changes after loading.
I64 DefineListCheck(CHashDefineStr *(*load)(U8 *name,U8 *list),
  I64 (*add)(U8 *name,I64 type,CHashTable *table),
  CHashTable *(*create)(I64 size,CTask *task),U0 (*destroy)(CHashTable *table),
  U0 (*release)(CHashSrcSym *entry),
  CHash *(*find)(U8 *name,CHashTable *table,I64 mask,I64 instance))
{
  U8 list[17],*initial="zero\0@alias\0one\0",*name="I386OwnedListProbe";
  CHashTable *symbols=Fs->hash_table,*table=(*create)(8,0);
  CHashDefineStr *entry;
  CHashGeneric *alias;
  CHash **link;
  I64 i,result=6;
  for(i=0;i<17;i++) list[i]=initial[i];
  entry=(*load)(name,list);
  list[0]='X'; list[12]='Y';
  if(entry->cnt!=2 || entry->data[0]!='z' || entry->sub_idx[0]!=entry->data ||
      entry->sub_idx[1]!=entry->data+12 || entry->sub_idx[1][0]!='o') result=-1;
  if(!entry->src_link || entry->src_link[0]!='A' || entry->src_link[1]!='D' ||
      entry->src_link[2]!=':' || entry->src_link[3]!='0' || entry->src_link[4]!='x') result=-2;
  if((*find)(name,symbols,HTT_DEFINE_STR,1)!=entry) result=-3;
  if((*add)(name,HTT_KEYWORD,table)!=2) result=-4;
  alias=(*find)("alias",table,HTT_KEYWORD,1);
  if(!alias || alias->user_data0) result=-5;
  alias=(*find)("one",table,HTT_KEYWORD,1);
  if(!alias || alias->user_data0!=1 || (*add)("I386MissingListProbe",HTT_KEYWORD,table)) result=-6;
  (*destroy)(table);
  //Unlink only the entry this test owns; preserve every other task symbol.
  for(i=0;i<=symbols->mask;i++) {
    link=&symbols->body[i];
    while(*link) {
      if(*link==entry) { *link=entry->next; (*release)(entry); return result; }
      link=&(*link)->next;
    }
  }
  return -7;
}
