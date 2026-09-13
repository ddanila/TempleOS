#include "/Kernel/I386/ModuleFile.HH"
#include "/Kernel/I386/ModuleAlloc.HC"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaExtent(CI386RedSea *v,I64 block,I64 size);
public U8 *I386RedSeaLoad(CI386RedSea *volume,CI386RedSeaEntry *entry,CI386Heap *heap,U8 *entry_name)
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
    image=I386LoadAlloc(heap,&file,&size,1,entry_name);
  if (!I386HeapFree(heap,file)) {
    if (image) I386HeapFree(heap,image);
    return 0;
  }
  return image;
}
public U8 *I386RedSeaLoadSet(CI386RedSea *volume,CI386RedSeaEntry *entries,I64 count,CI386Heap *heap,U8 *entry_name)
{//One linked image from an explicit file set. No dependency discovery or execution.
  U8 *metadata,*image=0,**files;
  I64 *sizes,i,pointer_bytes;
  Bool clean=TRUE;
  CI386RedSeaEntry *entry;
  if (!I386RedSeaValid(volume) || !entries || !entry_name || count<1 ||
      count>0xFFFFFFFF/sizeof(CI386RedSeaEntry) ||
      (entries+0)(U64)>0x100000000-count*sizeof(CI386RedSeaEntry) ||
      !I386HeapValid(heap)) return 0;
  if (count==1) return I386RedSeaLoad(volume,entries,heap,entry_name);
  for (i=0;i<count;i++) {
    entry=entries+i;
    if ((entry->attr&0x710) || !(entry->attr&0x800) || entry->size<32 ||
        entry->size>0xFFFFFFFF || !I386RedSeaExtent(volume,entry->block,entry->size)) return 0;
  }
  pointer_bytes=(count*sizeof(U8 *)+7)&~7;
  metadata=I386HeapAlloc(heap,pointer_bytes+count*8,TRUE);
  if (!metadata) return 0;
  files=metadata; sizes=metadata+pointer_bytes;
  for (i=0;i<count;i++) {
    sizes[i]=entries[i].size;
    files[i]=I386HeapAlloc(heap,sizes[i]);
    if (!files[i] || I386RedSeaRead(volume,entries+i,0,files[i],sizes[i])!=sizes[i]) goto done;
  }
  image=I386LoadAlloc(heap,files,sizes,count,entry_name);
done:
  for (i=0;i<count;i++)
    if (files[i] && !I386HeapFree(heap,files[i])) clean=FALSE;
  if (!I386HeapFree(heap,metadata)) clean=FALSE;
  if (!clean) {
    if (image) I386HeapFree(heap,image);
    return 0;
  }
  return image;
}
