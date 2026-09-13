#include "/Kernel/I386/RedSea.HH"
extern Bool I386RedSeaValid(CI386RedSea *v);
extern Bool I386RedSeaDirectory(CI386RedSea *v,I64 block,U8 *sector,I64 *size);
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
extern U0 I386RedSeaPutWord(U8 *p,U64 value);
public I64 I386RedSeaCreate(CI386RedSea *volume,I64 directory,U8 *name,U8 *buffer,I64 size,I64 datetime=0)
{//1 created, 0 exists/full, -1 invalid/I/O. Failure after reservation can leak space.
  U8 sector[512],*raw;
  CI386RedSeaEntry entry;
  I64 status,dir_size,index,slot=-1,blocks,i,next;
  Bool append=FALSE;
  if (!I386RedSeaValid(volume) || !volume->disk->flush || !I386RedSeaNewName(name) ||
      size<0 || size>0xFFFFFFFF || (size && !buffer) ||
      (buffer+0)(U64)>0x100000000-size) return -1;
  status=I386RedSeaFind(volume,directory,name,&entry);
  if (status<0) return -1;
  if (status) return 0;
  if (!I386RedSeaDirectory(volume,directory,sector,&dir_size) || (sector[0]&1)) return -1;
  for (index=0;index<dir_size/64;index++) {
    if (!(index&7) && index && !I386AtaRead(volume->disk,directory+index/8,sector)) return -1;
    raw=sector+(index&7)*64;
    if (!raw[2]) {
      if (slot<0) { slot=index; append=TRUE; }
      break;
    }
    if ((raw[1]&1) && slot<0) slot=index;
  }
  if (slot<0) return 0;
  blocks=(size+511)/512;
  if (blocks>volume->start+volume->sectors-volume->first) return 0;
  entry.attr=0x800; entry.block=0; entry.size=size; entry.datetime=datetime;
  if (blocks) {
    entry.block=I386RedSeaAlloc(volume,blocks);
    if (!entry.block) return 0;
    if (entry.block<0) return -1;
    if (I386RedSeaWrite(volume,&entry,0,buffer,size)!=size) goto io_fail;
  }
  //Reserve/data must reach the device's flush boundary before a name is published.
  if (!I386AtaFlush(volume->disk)) goto io_fail;
  next=slot+1;
  if (append && next<dir_size/64 && !(next&7)) {
    if (!I386AtaRead(volume->disk,directory+next/8,sector)) goto io_fail;
    for (i=0;i<64;i++) sector[i]=0;
    if (!I386AtaWrite(volume->disk,directory+next/8,sector) || !I386AtaFlush(volume->disk))
      goto io_fail;
  }
  if (!I386AtaRead(volume->disk,directory+slot/8,sector)) goto io_fail;
  if (append && next<dir_size/64 && (next&7))
    for (i=0;i<64;i++) sector[(next&7)*64+i]=0;
  raw=sector+(slot&7)*64;
  for (i=0;i<64;i++) raw[i]=0;
  raw[1]=8;
  i=0;
  while (name[i]) { raw[2+i]=name[i]; i++; }
  I386RedSeaPutWord(raw+40,entry.block);
  I386RedSeaPutWord(raw+48,size);
  I386RedSeaPutWord(raw+56,datetime);
  if (!I386AtaWrite(volume->disk,directory+slot/8,sector) || !I386AtaFlush(volume->disk))
    goto io_fail;
  return 1;
io_fail:
  volume->signature=0;
  return -1;
}
