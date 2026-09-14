#include "/Kernel/I386/FileLoad.HH"
#include "/Kernel/I386/Cpu.HH"
U8 *I386RedSeaFileLoad(CI386RedSea *volume,CI386Heap *heap,I64 directory,
  U8 *path,I64 *size=0,I64 *attr=0)
{
  CI386RedSeaEntry entry;
  I64 found,bytes=0,attributes;
  U8 *alternate,*raw,*result;
  if(GetRFlags&0x200 || !heap || !path) return 0;
  found=I386RedSeaResolve(volume,directory,path,&entry);
  if(!found) {
    alternate=I386ToggleZorNotZ(heap,path);
    if(!alternate) return 0;
    found=I386RedSeaResolve(volume,directory,alternate,&entry);
    I386HeapFree(heap,alternate);
  }
  if(found!=1) return 0;
  raw=I386RedSeaReadAll(volume,heap,&entry,&bytes);
  if(!raw) return 0;
  attributes=FileAttr(entry.name,entry.attr);
  if(attributes&RS_ATTR_COMPRESSED) {
    result=I386ExpandBuf(heap,raw,bytes,&bytes);
    I386HeapFree(heap,raw);
    if(!result) return 0;
  } else result=raw;
  if(size) *size=bytes;
  if(attr) *attr=attributes;
  return result;
}
