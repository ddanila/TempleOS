#include "/Kernel/I386/ModuleFile.HH"
#include "/Kernel/I386/ModuleAlloc.HC"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaExtent(CI386RedSea *v,I64 block,I64 size);
U8 *I386ModuleCompactPayload(CI386Heap *heap,U8 *file,I64 required,
  U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count)
{//Preflight is complete. This frame owns scratch only while resolving/copying.
  CI386ModuleHeader *h=file;
  CI386ModuleRecord *r;
  CI386SymbolIndex index;
  I64 address=(file+0)(U64),entry,matches,target,j;
  I386SymbolIndexBuild(&index,&file,1);
  entry=I386IndexedSymbol(&index,&file,1,entry_name,I386_MODULE_EXPORT,&matches);
  //Resolve with the original header and metadata intact. Only payload slots change.
  r=file+h->records_offset;
  for(j=0;j<h->record_count;j++,r++) {
    if(r->kind==I386_MODULE_POINTER)
      (file+32+r->offset)(U32 *)[0]=address+8+r->name_offset;
    else if(r->kind==I386_MODULE_NAMED_POINTER) {
      target=I386BoundSymbol(&file,1,file+r->name_offset,0,&matches,
        bindings,binding_count,address,&index);
      (file+32+r->offset)(U32 *)[0]=address+target;
    } else if(r->kind==I386_MODULE_REL32 || r->kind==I386_MODULE_ADDRESS) {
      target=I386BoundSymbol(&file,1,file+r->name_offset,0,&matches,
        bindings,binding_count,address,&index);
      (file+32+r->offset)(U32 *)[0]=target-(8+r->offset+4);
    }
  }
  //Forward copy is safe because the destination starts below the source.
  for(j=0;j<required-8;j++) file[8+j]=file[32+j];
  file[0]=0xE9; (file+1)(U32 *)[0]=entry-5;
  file[5]=0; file[6]=0; file[7]=0;
  if(!I386HeapShrink(heap,file,required)) return 0;
  return file;
}
U8 *I386ModuleCompactOwned(CI386Heap *heap,U8 *file,I64 size,
  U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count)
{//Keep validation scratch and compaction scratch out of the same call chain.
  I64 required,address=(file+0)(U64),j,n;
  if(I386HeapSize(heap,file)!=size) return 0;
  //Use the complete shared validation/resolution pass before any payload write.
  required=I386LoadBoundAt(&file,&size,1,0,0,entry_name,bindings,binding_count,address);
  if(!required) return 0;
  n=0; while(entry_name[n]) n++;
  if(I386BuffersOverlap(file,size,entry_name,n+1)) return 0;
  if(binding_count) {
    if(I386BuffersOverlap(file,size,bindings,binding_count*sizeof(CI386ModuleBinding))) return 0;
    for(j=0;j<binding_count;j++) {
      n=0; while(bindings[j].name[n]) n++;
      if(I386BuffersOverlap(file,size,bindings[j].name,n+1) ||
          ((bindings[j].address+0)(U64)>=address &&
           (bindings[j].address+0)(U64)-address<size)) return 0;
    }
  }
  return I386ModuleCompactPayload(heap,file,required,entry_name,bindings,binding_count);
}
public U8 *I386RedSeaLoadBound(CI386RedSea *volume,CI386RedSeaEntry *entry,CI386Heap *heap,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count)
{//Load one uncompressed module; caller invokes and eventually frees the image.
  U8 *file,*image=0;
  I64 size;
  if (!I386RedSeaValid(volume) || !entry || !entry_name || !I386HeapValid(heap) ||
      (entry->attr&0x710) || !(entry->attr&0x800) || entry->size<32 ||
      entry->size>0xFFFFFFFF || !I386RedSeaExtent(volume,entry->block,entry->size)) return 0;
  size=entry->size;
  file=I386HeapAlloc(heap,size);
  if (!file) return 0;
  if (I386RedSeaRead(volume,entry,0,file,size)==size)
    image=I386ModuleCompactOwned(heap,file,size,entry_name,bindings,binding_count);
  if(image) return image;
  I386HeapFree(heap,file);
  return 0;
}
public U8 *I386RedSeaLoad(CI386RedSea *volume,CI386RedSeaEntry *entry,CI386Heap *heap,U8 *entry_name)
{
  return I386RedSeaLoadBound(volume,entry,heap,entry_name,0,0);
}
