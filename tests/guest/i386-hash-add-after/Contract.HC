U0 HALog(U8 *s){while(*s)OutU8(0xE9,*s++);}
U0 HACheck()
{
  I64 used=Fs->data_heap->used_u8s,mask=0,i,flags,after,*result;
  CHashTable *table=HashTableNew(1);
  CHashGeneric *n[7];U8 *s;
  for(i=0;i<7;i++) {
    n[i]=CAlloc(sizeof(CHashGeneric));n[i]->str=StrNew("InsertAfterTest");
    n[i]->type=HTT_KEYWORD;n[i]->user_data0=i;
  }
  HashAdd(n[1],table);HashAdd(n[0],table);
  HashAddAfter(n[2],n[0],table);
  if(table->body[0]==n[0] && n[0]->next==n[2] && n[2]->next==n[1])mask|=1;
  HashAddAfter(n[3],n[1],table);
  if(n[1]->next==n[3] && !n[3]->next)mask|=2;
  HashAddAfter(n[4],table->body(CHash *),table);
  if(table->body[0]==n[4] && n[4]->next==n[0] && !table->locked_flags)mask|=4;
  for(i=0;i<7;i++)
    if(n[i]->type!=HTT_KEYWORD || n[i]->user_data0!=i || StrCmp(n[i]->str,"InsertAfterTest"))break;
  if(i==7)mask|=8;
  if(HashFind("InsertAfterTest",table,HTT_KEYWORD,1)==n[4] &&
      HashFind("InsertAfterTest",table,HTT_KEYWORD,2)==n[0] &&
      HashFind("InsertAfterTest",table,HTT_KEYWORD,3)==n[2] &&
      HashFind("InsertAfterTest",table,HTT_KEYWORD,4)==n[1] &&
      HashFind("InsertAfterTest",table,HTT_KEYWORD,5)==n[3])mask|=16;
  flags=GetRFlags;SetRFlags(flags&~512);
  HashAddAfter(n[5],n[3],table);after=GetRFlags;SetRFlags(flags);
  if(!(after&512) && n[3]->next==n[5] && !n[5]->next)mask|=32;
  SetRFlags(flags|512);
  HashAddAfter(n[6],n[5],table);after=GetRFlags;SetRFlags(flags);
  if(after&512 && n[5]->next==n[6] && !n[6]->next)mask|=64;
  HashTableDel(table);
  if(Fs->data_heap->used_u8s==used)mask|=128;
  result=MAlloc(8);*result=mask;
  s=MStrPrint("EXPORT hash-add-after-mask.bin %X 8\n",result);HALog(s);Free(s);
  HALog("HASH ADD AFTER DONE\n");Sleep(1000);
}
HACheck;
