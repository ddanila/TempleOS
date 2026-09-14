#include "/Kernel/I386/ModuleFileSingle.HC"
public U8 *I386RedSeaLoadSetBound(CI386RedSea *volume,CI386RedSeaEntry *entries,I64 count,CI386Heap *heap,U8 *entry_name,CI386ModuleBinding *bindings,I64 binding_count)
{//One linked image from an explicit file set. No dependency discovery or execution.
  U8 *metadata,*image=0,**files;
  I64 *sizes,i,pointer_bytes;
  Bool clean=TRUE;
  CI386RedSeaEntry *entry;
  if (!I386RedSeaValid(volume) || !entries || !entry_name || count<1 ||
      count>0xFFFFFFFF/sizeof(CI386RedSeaEntry) ||
      (entries+0)(U64)>0x100000000-count*sizeof(CI386RedSeaEntry) ||
      !I386HeapValid(heap)) return 0;
  if (count==1) return I386RedSeaLoadBound(volume,entries,heap,entry_name,bindings,binding_count);
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
  image=I386LoadBoundAlloc(heap,files,sizes,count,entry_name,bindings,binding_count);
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

public U8 *I386RedSeaLoadSet(CI386RedSea *volume,CI386RedSeaEntry *entries,I64 count,CI386Heap *heap,U8 *entry_name)
{
  return I386RedSeaLoadSetBound(volume,entries,count,heap,entry_name,0,0);
}
