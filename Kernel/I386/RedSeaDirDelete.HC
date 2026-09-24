#include "/Kernel/I386/RedSea.HH"
public I64 I386RedSeaDirDelete(CI386RedSea *volume,I64 directory,U8 *name)
{//1 removed, 0 absent/nonempty, -1 invalid/I/O. Root and traversal names are invalid.
  U8 sector[512],child_sector[512],*raw;
  CI386RedSeaEntry entry;
  I64 status,dir_size,child_size,index,i,blocks;
  Bool terminated=FALSE;
  if(!I386RedSeaValid(volume) || !volume->disk->flush ||
     !I386RedSeaNewName(name) || !I386RedSeaDirectory(volume,directory,sector,&dir_size) ||
     (sector[0]&1)) return -1;
  status=I386RedSeaFind(volume,directory,name,&entry);
  if(status<=0) return status;
  if(!(entry.attr&0x10) || (entry.attr&1) || entry.block==volume->root ||
     !I386RedSeaDirectory(volume,entry.block,child_sector,&child_size)) return -1;
  //Only . and .. may be live. Deleted slots are harmless; a terminator is required.
  for(index=2;index<child_size/64;index++) {
    if(!(index&7) && index && !I386RedSeaSectorRead(volume,entry.block+index/8,child_sector))
      goto io_fail;
    raw=child_sector+(index&7)*64;
    if(!raw[2]) { terminated=TRUE; break; }
    if(!(raw[1]&1)) return 0;
  }
  if(!terminated) goto io_fail;
  //Find has validated the parent record; exclusive ownership keeps it stable.
  for(index=0;index<dir_size/64;index++) {
    if(!(index&7) && index && !I386RedSeaSectorRead(volume,directory+index/8,sector))
      goto io_fail;
    raw=sector+(index&7)*64;
    if(!raw[2]) goto io_fail;
    if(!(raw[1]&1)) {
      i=0;
      while(i<38 && raw[2+i]==entry.name[i]) {
        if(!entry.name[i]) {
          raw[1]|=1;
          if(!I386RedSeaSectorWrite(volume,directory+index/8,sector) ||
             !I386RedSeaFlush(volume)) goto io_fail;
          blocks=child_size/512;
          if(!blocks || !I386RedSeaFree(volume,entry.block,blocks) ||
             !I386RedSeaFlush(volume)) goto io_fail;
          return 1;
        }
        i++;
      }
    }
  }
io_fail:
  volume->signature=0;
  return -1;
}
