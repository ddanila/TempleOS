#include "/Kernel/I386/ModuleFile.HH"
#include "/Kernel/I386/ModuleAlloc.HC"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaExtent(CI386RedSea *v,I64 block,I64 size);
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
    image=I386LoadBoundAlloc(heap,&file,&size,1,entry_name,bindings,binding_count);
  if (!I386HeapFree(heap,file)) {
    if (image) I386HeapFree(heap,image);
    return 0;
  }
  return image;
}
public U8 *I386RedSeaLoad(CI386RedSea *volume,CI386RedSeaEntry *entry,CI386Heap *heap,U8 *entry_name)
{
  return I386RedSeaLoadBound(volume,entry,heap,entry_name,0,0);
}
