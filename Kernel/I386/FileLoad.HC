#include "/Kernel/I386/FileLoad.HH"
#include "/Kernel/I386/Cpu.HH"
I64 I386RedSeaParentFind(CI386RedSea *volume,CI386Heap *heap,I64 directory,
  U8 *path,CI386RedSeaEntry *entry)
{
  CI386RedSeaEntry parent;
  U8 *leaf=path,*cursor=path,*prefix;
  I64 length,result,i,anchor,power=1,span=0,hops=0;
  while(*cursor) { if(*cursor=='/') leaf=cursor+1; cursor++; }
  if(!*leaf) return -1;
  length=leaf-path;
  if(length) {
    prefix=I386HeapAlloc(heap,length+1,FALSE);
    if(!prefix) return -1;
    for(i=0;i<length;i++) prefix[i]=path[i];
    prefix[length]=0;
    result=I386RedSeaResolve(volume,directory,prefix,&parent);
    I386HeapFree(heap,prefix);
  } else result=I386RedSeaResolve(volume,directory,".",&parent);
  if(result!=1) return result;
  if(!(parent.attr&RS_ATTR_DIR)) return -1;
  directory=anchor=parent.block;
  while(directory!=volume->root) {
    if(hops>=volume->sectors) return -1;
    hops++;
    if(I386RedSeaResolve(volume,directory,"..",&parent)!=1 || !(parent.attr&RS_ATTR_DIR)) return -1;
    directory=parent.block;
    result=I386RedSeaFind(volume,directory,leaf,entry);
    if(result==1 && entry->attr&RS_ATTR_DIR) result=0;
    if(result) return result;
    //Brent cycle detection uses one parent transition per candidate and constant storage.
    if(directory==anchor) return -1;
    if(++span==power) {
      anchor=directory; span=0;
      if(power>volume->sectors/2) power=volume->sectors;
      else power*=2;
    }
  }
  return 0;
}
I64 I386RedSeaFileLocate(CI386RedSea *volume,CI386Heap *heap,I64 directory,
  U8 *path,CI386RedSeaEntry *entry,Bool scan_parents)
{
  U8 *alternate;
  I64 result=I386RedSeaResolve(volume,directory,path,entry);
  if(result==1 && scan_parents && entry->attr&RS_ATTR_DIR) result=0;
  if(result) return result;
  alternate=I386ToggleZorNotZ(heap,path);
  if(!alternate) return -1;
  result=I386RedSeaResolve(volume,directory,alternate,entry);
  if(result==1 && scan_parents && entry->attr&RS_ATTR_DIR) result=0;
  if(!result && scan_parents) {
    result=I386RedSeaParentFind(volume,heap,directory,path,entry);
    if(!result) result=I386RedSeaParentFind(volume,heap,directory,alternate,entry);
  }
  I386HeapFree(heap,alternate);
  return result;
}
U8 *I386RedSeaFileLoad(CI386RedSea *volume,CI386Heap *heap,I64 directory,
  U8 *path,I64 *size=0,I64 *attr=0,Bool scan_parents=FALSE)
{
  CI386RedSeaEntry entry;
  I64 found,bytes=0,attributes;
  U8 *raw,*result;
  if(GetRFlags&0x200 || !heap || !path) return 0;
  found=I386RedSeaFileLocate(volume,heap,directory,path,&entry,scan_parents);
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
