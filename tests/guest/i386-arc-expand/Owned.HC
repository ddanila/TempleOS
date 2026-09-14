I64 expand_arenas[8]={24,32784,32792,32816,98480,98488,102592,102600};
Bool ExpandReject(CI386Heap *heap,CArcCompress *arc,I64 bytes)
{
  I64 size=-77,used=heap->used,count=heap->allocations;
  U8 *p=I386ExpandBuf(heap,arc,bytes,&size);
  if(p) { I386HeapFree(heap,p); return FALSE; }
  return size==-77 && heap->used==used && heap->allocations==count && I386HeapValid(heap);
}
I64 OwnedExpandTest()
{
  CI386Heap heap;
  CArcCompress *arc,*bad;
  CArcCtrl *c;
  CI386ArcCheck check;
  U8 *p,raw[512];
  I64 i,j,v,offset=8,pattern,packed,size,expected;
  U32 random,flags;
  if(!I386HeapInit(&heap,0x60000,131072)) return 31;
  OutU8(0x21,255); OutU8(0xA1,255);
  for(v=0;v<6;v++) {
    pattern=(archive_vectors+offset)(I64 *)[0]; packed=(archive_vectors+offset)(I64 *)[1];
    arc=archive_vectors+offset+16;
    flags=0; if(v&1) flags=0x200;
    SetRFlags((GetRFlags&~0x200)|flags);
    size=-77; p=I386ExpandBuf(&heap,arc,packed,&size);
    if(!p || size!=arc->expanded_size || I386HeapSize(&heap,p)!=size+1 || p[size] ||
        (GetRFlags&0x200)!=flags || heap.allocations!=1) return 32;
    random=0x12345678;
    for(i=0;i<size;i++) {
      random=random*1664525+1013904223; expected=random>>24;
      if(pattern==0) expected='Q';
      if(arc->compression_type==CT_7_BIT) expected&=127;
      if(p[i]!=expected) return 33;
    }
    if(!I386HeapFree(&heap,p) || heap.used || heap.allocations) return 34;
    offset+=16+packed;
  }
  SetRFlags(GetRFlags&~0x200);
  for(i=0;i<32;i++) raw[i]=0;
  bad=raw; bad->compression_type=CT_NONE; bad->compressed_size=19; bad->expanded_size=2;
  raw[17]=0; raw[18]=0x80;
  p=I386ExpandBuf(&heap,bad,19);
  if(!p || p[0] || p[1]!=0x80 || p[2] || I386HeapSize(&heap,p)!=3 || !I386HeapFree(&heap,p)) return 35;
  for(i=CT_NONE;i<=CT_8_BIT;i++) {
    bad->compression_type=i; bad->compressed_size=17; bad->expanded_size=0;
    p=I386ExpandBuf(&heap,bad,17,&size);
    if(!p || size || *p || I386HeapSize(&heap,p)!=1 || !I386HeapFree(&heap,p)) return 36;
  }
  bad->compressed_size=18;
  if(!ExpandReject(&heap,bad,18)) return 51;
  if(!ExpandReject(&heap,0,17) || !ExpandReject(&heap,0xFFFFFFF8,17) ||
      !ExpandReject(&heap,bad,-1) || !ExpandReject(&heap,bad,16) ||
      !ExpandReject(&heap,bad,0x100000000)) return 37;
  for(i=0;i<7;i++) {
    bad->compression_type=CT_NONE; bad->compressed_size=19; bad->expanded_size=2;
    if(i==0) bad->compressed_size=-1;
    if(i==1) bad->compressed_size=16;
    if(i==2) bad->compressed_size=20;
    if(i==3) bad->expanded_size=-1;
    if(i==4) bad->expanded_size=3;
    if(i==5) bad->compression_type=0;
    if(i==6) bad->compression_type=4;
    if(!ExpandReject(&heap,bad,19)) return 38;
  }
  bad->compression_type=CT_7_BIT; bad->compressed_size=17; bad->expanded_size=0x100000000;
  if(!ExpandReject(&heap,bad,32)) return 39;
  //Two 8-bit codes: literal A followed by the special current entry (AA).
  bad->compression_type=CT_7_BIT; bad->compressed_size=19; bad->expanded_size=3;
  raw[17]='A'; raw[18]=128;
  p=I386ExpandBuf(&heap,bad,19,&size);
  if(!p || size!=3 || p[0]!='A' || p[1]!='A' || p[2]!='A' || p[3] || !I386HeapFree(&heap,p)) return 40;
  for(i=0;i<6;i++) {
    bad->compressed_size=19; bad->expanded_size=3; raw[17]='A'; raw[18]=128;
    if(i==0) raw[17]=128;
    if(i==1) raw[18]=200;
    if(i==2) bad->expanded_size=1;
    if(i==3) bad->expanded_size=2;
    if(i==4) bad->expanded_size=4;
    if(i==5) bad->compressed_size=18;
    if(!ExpandReject(&heap,bad,19)) return 41;
  }
  //Chain validation refuses unwritten entries, cycles, and overwriting an ancestor.
  c=I386ArcCtrlNew(&heap,TRUE,CT_7_BIT); if(!c) return 42;
  for(i=0;i<512;i++) check.valid[i]=0;
  if(I386ArcChain(&check,c,128,-1)!=-1) return 43;
  check.valid[16]=3; c->compress[128].basecode=129; c->compress[129].basecode=128;
  if(I386ArcChain(&check,c,128,-1)!=-1 || I386ArcChain(&check,c,128,128)!=-1) return 44;
  c->compress[129].basecode='A';
  if(I386ArcChain(&check,c,128,-1)!=3 || !I386ArcCtrlDel(&heap,c)) return 45;
  if(heap.used || heap.allocations) return 46;
  arc=archive_vectors+24;
  packed=arc->compressed_size;
  if(packed>512) return 52;
  for(i=0;i<packed;i++) raw[i]=(arc+0)(U8 *)[i];
  bad=raw;
  for(j=0;j<32;j++) {
    i=17+(j*7)%(packed-17); raw[i]^=1<<(j&7);
    size=-77; p=I386ExpandBuf(&heap,bad,packed,&size);
    if(p) {
      if(size!=32768 || p[size] || I386HeapSize(&heap,p)!=size+1 || !I386HeapFree(&heap,p)) return 53;
    } else if(size!=-77) return 54;
    if(heap.used || heap.allocations || !I386HeapValid(&heap)) return 55;
    raw[i]^=1<<(j&7);
  }
  for(j=0;j<8;j++) {
    if(!I386HeapInit(&heap,0x60000,expand_arenas[j])) return 47;
    if(j<7) { if(!ExpandReject(&heap,arc,arc->compressed_size)) return 48; }
    else {
      p=I386ExpandBuf(&heap,arc,arc->compressed_size,&size);
      if(!p || size!=32768 || heap.used!=32792 || heap.allocations!=1 ||
          !I386HeapFree(&heap,p)) return 49;
    }
    if(heap.used || heap.allocations || !I386HeapValid(&heap)) return 50;
  }
  return 0;
}
