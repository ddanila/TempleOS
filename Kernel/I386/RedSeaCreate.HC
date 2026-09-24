#include "/Kernel/I386/RedSea.HH"
#ifndef I386_REDSEA_MUTATION_IMPORTS
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaDirectory(CI386RedSea *v,I64 block,U8 *sector,I64 *size);
#endif
Bool I386RedSeaNewName(U8 *name)
{//Existing filename character bitmap; creation excludes the two traversal names.
  I64 i=0,ch,group;
  U32 bits;
  if (!name || !name[0] || (name[0]=='.' && (!name[1] || (name[1]=='.' && !name[2]))))
    return FALSE;
  while (i<38 && name[i]) {
    ch=name[i]; group=ch>>5; bits=0xFFFFFFFF;
    if (!group) bits=0;
    if (group==1) bits=0x03FF73FB;
    if (group==2) bits=0xEFFFFFFF;
    if (group==3) bits=0x2FFFFFFF;
    if (!((bits>>(ch&31))&1)) return FALSE;
    i++;
  }
  return i<38;
}
#ifndef I386_REDSEA_MUTATION_IMPORTS
extern U0 I386RedSeaPutWord(U8 *p,U64 value);
#endif
I64 I386RedSeaCreateGetWord(U8 *p)
{
  I64 value=0,i;
  for(i=0;i<8;i++) value|=(p[i]+0)(U64)<<(8*i);
  return value;
}
Bool I386RedSeaReparentRootChildren(CI386RedSea *volume,I64 root,I64 size,I64 parent)
{//A moved root changes the on-disk parent record of each direct child directory.
  U8 root_sector[512],child_sector[512],*raw,*up;
  I64 index,child,child_size,i;
  for(index=2;index<size/64;index++) {
    if(!(index&7) || index==2)
      if(!I386RedSeaSectorRead(volume,root+index/8,root_sector)) return FALSE;
    raw=root_sector+(index&7)*64;
    if(!raw[2]) break;
    if(!(raw[1]&1) && (raw[0]&0x10)) {
      child=0;
      for(i=0;i<8;i++) child|=(raw[40+i]+0)(U64)<<(8*i);
      if(child==root || !I386RedSeaDirectory(volume,child,child_sector,&child_size))
        return FALSE;
      up=child_sector+64;
      if((up[0]&0x10)==0 || (up[1]&1) || up[2]!='.' || up[3]!='.' || up[4])
        return FALSE;
      I386RedSeaPutWord(up+40,parent);
      if(!I386RedSeaSectorWrite(volume,child,child_sector)) return FALSE;
    }
  }
  return I386RedSeaFlush(volume);
}
I64 I386RedSeaGrowRoot(CI386RedSea *volume,I64 size)
{//Relocate a full root directory and add one zeroed sector.
  U8 sector[512],boot[512],*raw;
  I64 old=volume->root,old_blocks=size/512,new_blocks=old_blocks+1;
  I64 fresh,i,boot_root=0;
  if(size<512 || (size&511)) return -1;
  fresh=I386RedSeaAlloc(volume,new_blocks);
  if(fresh<=0) return fresh;
  for(i=0;i<old_blocks;i++) {
    if(!I386RedSeaSectorRead(volume,old+i,sector)) goto io_fail;
    if(!i) {
      raw=sector;
      I386RedSeaPutWord(raw+40,fresh);
      I386RedSeaPutWord(raw+48,size+512);
      raw=sector+64;
      if(raw[2]=='.' && raw[3]=='.' && !raw[4])
        I386RedSeaPutWord(raw+40,fresh);
    }
    if(!I386RedSeaSectorWrite(volume,fresh+i,sector)) goto io_fail;
  }
  for(i=0;i<512;i++) sector[i]=0;
  if(!I386RedSeaSectorWrite(volume,fresh+old_blocks,sector) ||
      !I386RedSeaFlush(volume)) goto io_fail;
  if(!I386RedSeaSectorRead(volume,volume->start,boot)) goto io_fail;
  for(i=0;i<8;i++) boot_root|=(boot[24+i]+0)(U64)<<(8*i);
  if(boot_root!=old) goto io_fail;
  I386RedSeaPutWord(boot+24,fresh);
  if(!I386RedSeaSectorWrite(volume,volume->start,boot) ||
      !I386RedSeaFlush(volume)) goto io_fail;
  volume->root=fresh;
  if(!I386RedSeaReparentRootChildren(volume,fresh,size+512,fresh)) goto io_fail;
  if(!I386RedSeaFree(volume,old,old_blocks) || !I386RedSeaFlush(volume)) {
    volume->signature=0; return -1;
  }
  return fresh;
io_fail:
  volume->signature=0;
  return -1;
}
I64 I386RedSeaGrowDirectory(CI386RedSea *volume,I64 directory,I64 size)
{//Relocate a full non-root directory, relink its parent, and retain a terminator.
  U8 sector[512],parent_sector[512],*raw;
  I64 old_blocks=size/512,new_blocks=old_blocks+1,fresh,parent,parent_size;
  I64 i,index,slot=-1;
  if(directory==volume->root) return I386RedSeaGrowRoot(volume,size);
  if(size<512 || (size&511) ||
      !I386RedSeaSectorRead(volume,directory,sector) ||
      sector[64]!=0x10 || sector[65]!=0x08 || sector[66]!='.' ||
      sector[67]!='.' || sector[68])
    return -1;
  parent=I386RedSeaCreateGetWord(sector+64+40);
  if(parent==directory || !I386RedSeaDirectory(volume,parent,parent_sector,&parent_size))
    return -1;
  fresh=I386RedSeaAlloc(volume,new_blocks);
  if(fresh<=0) return fresh;
  for(i=0;i<old_blocks;i++) {
    if(!I386RedSeaSectorRead(volume,directory+i,sector)) goto io_fail;
    if(!i) {
      I386RedSeaPutWord(sector+40,fresh);
      I386RedSeaPutWord(sector+48,size+512);
    }
    if(!I386RedSeaSectorWrite(volume,fresh+i,sector)) goto io_fail;
  }
  for(i=0;i<512;i++) sector[i]=0;
  if(!I386RedSeaSectorWrite(volume,fresh+old_blocks,sector) ||
      !I386RedSeaFlush(volume)) goto io_fail;
  for(index=2;index<parent_size/64;index++) {
    if(!(index&7) || index==2)
      if(!I386RedSeaSectorRead(volume,parent+index/8,parent_sector)) goto io_fail;
    raw=parent_sector+(index&7)*64;
    if(!raw[2]) break;
    if(raw[0]==0x10 && raw[1]==0x08 &&
        I386RedSeaCreateGetWord(raw+40)==directory) { slot=index; break; }
  }
  if(slot<0) goto io_fail;
  if(!I386RedSeaSectorRead(volume,parent+slot/8,parent_sector)) goto io_fail;
  raw=parent_sector+(slot&7)*64;
  I386RedSeaPutWord(raw+40,fresh); I386RedSeaPutWord(raw+48,size+512);
  if(!I386RedSeaSectorWrite(volume,parent+slot/8,parent_sector) ||
      !I386RedSeaFlush(volume)) goto io_fail;
  if(!I386RedSeaReparentRootChildren(volume,fresh,size+512,fresh)) goto io_fail;
  if(!I386RedSeaFree(volume,directory,old_blocks) || !I386RedSeaFlush(volume)) {
    volume->signature=0; return -1;
  }
  return fresh;
io_fail:
  volume->signature=0;
  return -1;
}
public I64 I386RedSeaCreate(CI386RedSea *volume,I64 directory,U8 *name,U8 *buffer,I64 size,I64 datetime=0,I64 attr=0x800)
{//1 created, 0 exists/full, -1 invalid/I/O. Failure after reservation can leak space.
  U8 sector[512],*raw;
  CI386RedSeaEntry entry;
  I64 status,dir_size,index,slot=-1,blocks,i,next,grown;
  Bool append=FALSE;
  if (!I386RedSeaValid(volume) || !volume->disk->flush || !I386RedSeaNewName(name) ||
      size<0 || size>0xFFFFFFFF || (size && !buffer) ||
      (buffer+0)(U64)>0x100000000-size) return -1;
  status=I386RedSeaFind(volume,directory,name,&entry);
  if (status<0) return -1;
  if (status) return 0;
  if (!I386RedSeaDirectory(volume,directory,sector,&dir_size) || (sector[0]&1)) return -1;
  for (index=0;index<dir_size/64;index++) {
    if (!(index&7) && index && !I386RedSeaSectorRead(volume,directory+index/8,sector)) return -1;
    raw=sector+(index&7)*64;
    if (!raw[2]) {
      if (slot<0) { slot=index; append=TRUE; }
      break;
    }
    if ((raw[1]&1) && slot<0) slot=index;
  }
  //The last slot must remain zero so directory walkers have a terminator.
  if (slot<0 || append && slot+1>=dir_size/64) {
    grown=I386RedSeaGrowDirectory(volume,directory,dir_size);
    if(grown<=0) return grown;
    directory=grown;
    if(slot<0) slot=dir_size/64;
    dir_size+=512; append=TRUE;
  }
  blocks=(size+511)/512;
  if (blocks>volume->start+volume->sectors-volume->first) return 0;
  //Data is written before publication; the raw directory entry receives attr.
  entry.attr=0x800; entry.block=0; entry.size=size; entry.datetime=datetime;
  if (blocks) {
    entry.block=I386RedSeaAlloc(volume,blocks);
    if (!entry.block) return 0;
    if (entry.block<0) return -1;
    if (I386RedSeaWrite(volume,&entry,0,buffer,size)!=size) goto io_fail;
  }
  //Reserve/data must reach the device's flush boundary before a name is published.
  if (!I386RedSeaFlush(volume)) goto io_fail;
  next=slot+1;
  if (append && next<dir_size/64 && !(next&7)) {
    if (!I386RedSeaSectorRead(volume,directory+next/8,sector)) goto io_fail;
    for (i=0;i<64;i++) sector[i]=0;
    if (!I386RedSeaSectorWrite(volume,directory+next/8,sector) || !I386RedSeaFlush(volume))
      goto io_fail;
  }
  if (!I386RedSeaSectorRead(volume,directory+slot/8,sector)) goto io_fail;
  if (append && next<dir_size/64 && (next&7))
    for (i=0;i<64;i++) sector[(next&7)*64+i]=0;
  raw=sector+(slot&7)*64;
  for (i=0;i<64;i++) raw[i]=0;
  raw[0]=attr; raw[1]=attr>>8;
  i=0;
  while (name[i]) { raw[2+i]=name[i]; i++; }
  I386RedSeaPutWord(raw+40,entry.block);
  I386RedSeaPutWord(raw+48,size);
  I386RedSeaPutWord(raw+56,datetime);
  if (!I386RedSeaSectorWrite(volume,directory+slot/8,sector) || !I386RedSeaFlush(volume))
    goto io_fail;
  return 1;
io_fail:
  volume->signature=0;
  return -1;
}
