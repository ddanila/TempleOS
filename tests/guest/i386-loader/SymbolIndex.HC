//Differential lookup oracle, collisions, duplicate matches and capacity fallback.
//Fixed test scratch is below the reserved stack and below the high-memory heap.
U8 *symbol_fixture=0x50000;
I64 SymbolIndexStress()
{
  CI386SymbolIndex index;
  CI386ModuleHeader *h=symbol_fixture;
  CI386ModuleRecord *r;
  U8 *modules[2],*name,*hex="0123456789ABCDEF",loaded[32];
  I64 sizes[2],c,i,k,expected,actual,em,am;
  I64 counts[4];
  counts[0]=1; counts[1]=128; counts[2]=512; counts[3]=513;
  h->magic=I386_MODULE_MAGIC; h->version=I386_MODULE_VERSION;
  h->cpu=3; h->pointer_size=4; h->abi=I386_MODULE_ABI;
  h->code_size=8; h->records_offset=40;
  for(c=0;c<4;c++) {
    h->record_count=counts[c]; h->strings_offset=40+counts[c]*16;
    h->total_size=h->strings_offset+counts[c]*6;
    r=symbol_fixture+40;
    for(i=0;i<counts[c];i++,r++) {
      r->kind=I386_MODULE_EXPORT; r->offset=i&7;
      r->name_offset=h->strings_offset+i*6; r->name_length=5;
      name=symbol_fixture+r->name_offset; name[0]='N'; name[5]=0;
      for(k=0;k<4;k++) name[k+1]=hex[(i>>(4*(3-k)))&15];
    }
    modules[0]=modules[1]=symbol_fixture; sizes[0]=sizes[1]=h->total_size;
    if(!I386ModuleValid(symbol_fixture,h->total_size)) return 601;
    I386SymbolIndexBuild(&index,modules,1);
    if(index.complete!=(counts[c]<=512)) return 602;
    r=symbol_fixture+40;
    for(i=0;i<counts[c];i++,r++)
      for(k=0;k<4;k++) {
        name=symbol_fixture+r->name_offset;
        expected=I386FindSymbol(modules,1,name,k,&em);
        actual=I386IndexedSymbol(&index,modules,1,name,k,&am);
        if(em!=am || em==1 && expected!=actual) return 603;
      }
    I386IndexedSymbol(&index,modules,1,"Missing",0,&am);
    if(am || I386LoadBoundAt(modules,sizes,1,loaded,32,"N0000",0,0,0x10000)!=16)
      return 604;
    I386SymbolIndexBuild(&index,modules,2);
    expected=I386FindSymbol(modules,2,"N0000",1,&em);
    actual=I386IndexedSymbol(&index,modules,2,"N0000",1,&am);
    if(em!=2 || am!=2) return 605;
    for(i=0;i<32;i++) loaded[i]=0xA5;
    if(I386LoadBoundAt(modules,sizes,2,loaded,32,"N0000",0,0,0x10000)) return 606;
    for(i=0;i<32;i++) if(loaded[i]!=0xA5) return 607;
  }
  return 0;
}
