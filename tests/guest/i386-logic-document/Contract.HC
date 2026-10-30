I64 LogicDocumentContract(U8 *path)
{
  CDoc *doc=NULL;CDocBin *bin,*match;CDocEntry *entry;
  U8 *raw=NULL,*p;I64 size,i,record_count=0,ins=0,sprites=0,mask=0;
  Bool valid=TRUE;
  raw=FileRead(path,&size);doc=DocRead(path);
  if(!raw || !doc)goto logic_doc_done;
  p=raw;while(p<raw+size && *p)p++;
  if(p>=raw+size)goto logic_doc_done;
  p++;
  while(p<raw+size) {
    U32 number,flags,length;I64 matches=0;
    if(raw+size-p<16){valid=FALSE;break;}
    number=*(p+0)(U32 *);flags=*(p+4)(U32 *);length=*(p+8)(U32 *);p+=16;
    if(length>raw+size-p){valid=FALSE;break;}
    match=NULL;bin=doc->bin_head.next;
    while(bin!=&doc->bin_head) {
      if(bin->num==number){match=bin;matches++;}
      bin=bin->next;
    }
    if(matches!=1 || !match || match->flags!=flags || match->size!=length ||
        !match->data || MemCmp(match->data,p,length))valid=FALSE;
    record_count++;p+=length;
  }
  if(valid && p==raw+size && record_count==10)mask|=1;
  bin=doc->bin_head.next;i=0;
  while(bin!=&doc->bin_head){i++;bin=bin->next;}
  if(i==10)mask|=2;
  valid=TRUE;entry=doc->head.next;
  while(entry!=doc) {
    if(entry->type_u8==DOCT_INS_BIN || entry->type_u8==DOCT_SPRITE) {
      if(entry->type_u8==DOCT_INS_BIN)ins++;else sprites++;
      if(!entry->bin_data || entry->bin_data->num!=entry->bin_num ||
          !(entry->de_flags&DOCEF_HAS_BIN))valid=FALSE;
    }
    entry=entry->next;
  }
  if(ins==10)mask|=4;
  if(sprites==10)mask|=8;
  if(valid)mask|=16;
logic_doc_done:
  Free(raw);DocDel(doc);return mask;
}
