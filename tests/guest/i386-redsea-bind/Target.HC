#include "/Kernel/Types.HH"
#define TRUE 1
#define FALSE 0
#define U32_MAX 0xFFFFFFFF
#include "/Kernel/I386/ModuleFile.HH"
I64 resident_salt;
I64 ResidentAdd(I64 value) { resident_salt+=value; return value*2; }
U0 BindInit(CI386ModuleBinding *bindings)
{
  bindings[0].name="Add"; bindings[0].kind=1;
  bindings[0].address=(&ResidentAdd+0)(U64);
  bindings[1].name="salt"; bindings[1].kind=3;
  bindings[1].address=(&resident_salt+0)(U64);
}
I64 Main(I64 a,I64 b)
{
  CI386Ata disk;
  CI386RedSea v;
  CI386RedSeaEntry entries[2];
  CI386Heap heap;
  CI386ModuleBinding bindings[3];
  CI386ModuleHeader *h;
  CI386ModuleRecord *r;
  U8 *module,*image,out[1024],long_name[257];
  I64 size,required,i,j;
  U32 expected;
  I64 (*entry_point)(I64 x,I64 y);
  if (!I386AtaIdentify(&disk,0,0) || !I386RedSeaMount(&v,&disk,2048) ||
      !I386HeapInit(&heap,(0x40000)(U8 *),65536) ||
      I386RedSeaFind(&v,v.root,"Consumer.T32M",entries)!=1 ||
      I386RedSeaFind(&v,v.root,"Provider.T32M",entries+1)!=1) return 1;
  size=entries[0].size; module=I386HeapAlloc(&heap,size);
  if (!module || I386RedSeaRead(&v,entries,0,module,size)!=size) return 2;
  BindInit(bindings);
  required=I386LoadBoundInto(&module,&size,1,0,0,"Main",bindings,2);
  if (required<8 || required>1024) return 3;
  for (i=0;i<1024;i++) out[i]=0xA5;
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",0,2) ||
      I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,-1) ||
      I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,1) ||
      I386LoadBoundInto(&module,&size,1,out,1024,"Main",(0xFFFFFFF8)(CI386ModuleBinding *),2))
    return 4;
  bindings[0].kind=3;
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,2)) return 5;
  BindInit(bindings); bindings[0].address=0;
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,2)) return 6;
  BindInit(bindings);
  bindings[2].name="Add"; bindings[2].kind=1; bindings[2].address=bindings[0].address;
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,3)) return 7;
  bindings[2].name="Main";
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,3)) return 8;
  for (i=0;i<256;i++) long_name[i]='A';
  long_name[256]=0; bindings[2].name=long_name;
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,3)) return 9;
  if (I386LoadBoundInto(&module,&size,1,bindings,1024,"Main",bindings,2) ||
      I386LoadBoundInto(&module,&size,1,bindings[0].name,1024,"Main",bindings,2)) return 10;
  bindings[0].address=(out+0)(U64);
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,2)) return 11;
  for (i=0;i<1024;i++) if (out[i]!=0xA5) return 12;
  //Check full-width relative patching without executing the synthetic high address.
  BindInit(bindings); bindings[0].address=0xFFFFFFF0;
  if (I386LoadBoundInto(&module,&size,1,out,1024,"Main",bindings,2)!=required) return 13;
  h=module; r=module+h->records_offset;
  for (i=0;i<h->record_count;i++,r++) if (r->kind==2) {
    expected=0xFFFFFFF0-((out+0)(U64)+8+r->offset+4);
    if ((out+8+r->offset)(U32 *)[0]!=expected) return 14;
  }
  BindInit(bindings);
  if (I386RedSeaLoadSetBound(&v,entries,2,&heap,"Main",bindings,2) || heap.allocations!=1)
    return 15; //The file provider conflicts with the resident definitions.
  for (j=0;j<2;j++) {
    BindInit(bindings); resident_salt=0x100000000;
    if (!j) image=I386RedSeaLoadBound(&v,entries,&heap,"Main",bindings,2);
    else image=I386RedSeaLoadSetBound(&v,entries,1,&heap,"Main",bindings,2);
    if (!image || heap.allocations!=2) return 16;
    bindings[0].address=0; bindings[1].address=0; //Bindings are consumed during loading.
    entry_point=image;
    if ((*entry_point)(17,25)!=0x10000004C || resident_salt!=0x100000011) return 17;
    resident_salt=0x200000000;
    if ((*entry_point)(1,2)!=0x200000005 || !I386HeapFree(&heap,image)) return 18;
  }
  if (!I386HeapFree(&heap,module) || heap.used || heap.allocations || !I386HeapValid(&heap))
    return 19;
  return 0;
}
#include "/Kernel/I386/Ata.HC"
#include "/Kernel/I386/RedSea.HC"
#include "/Kernel/I386/ModuleFile.HC"
