#include "/Kernel/I386/RedSea.HH"
public I64 I386RedSeaRename(CI386RedSea *volume,I64 directory,U8 *old_name,U8 *new_name)
{//1 renamed, 0 absent/collision, -1 invalid/I/O. Same-directory entries only.
  U8 sector[512],*raw;
  CI386RedSeaEntry entry,collision;
  I64 status,dir_size,index,i;
  if(!I386RedSeaValid(volume) || !volume->disk->flush ||
     !I386RedSeaNewName(old_name) || !I386RedSeaNewName(new_name) ||
     !I386RedSeaDirectory(volume,directory,sector,&dir_size) ||
     (sector[0]&1)) return -1;
  status=I386RedSeaFind(volume,directory,old_name,&entry);
  if(status<=0) return status;
  if(entry.attr&1) return -1;
  status=I386RedSeaFind(volume,directory,new_name,&collision);
  if(status<0) return -1;
  if(status) return 0;
  for(index=0;index<dir_size/64;index++) {
    if(!(index&7) && index && !I386RedSeaSectorRead(volume,directory+index/8,sector))
      goto io_fail;
    raw=sector+(index&7)*64;
    if(!raw[2]) goto io_fail;
    if(!(raw[1]&1)) {
      i=0;
      while(i<38 && raw[2+i]==entry.name[i]) {
        if(!entry.name[i]) {
          for(i=0;i<38;i++) raw[2+i]=0;
          for(i=0;new_name[i];i++) raw[2+i]=new_name[i];
          if(!I386RedSeaSectorWrite(volume,directory+index/8,sector) ||
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
