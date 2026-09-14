#include "/Kernel/I386/RedSea.HH"
I64 I386RedSeaWord(U8 *p)
{
  U64 value=0;
  I64 i;
  for (i=0;i<8;i++) value|=(p[i]+0)(U64)<<(8*i);
  return value;
}
U0 I386RedSeaPutWord(U8 *p,U64 value)
{
  I64 i;
  for (i=0;i<8;i++) p[i]=value>>(8*i);
}
Bool I386RedSeaValid(CI386RedSea *v)
{
  return v && v->signature==0x52533332 && v->disk &&
    v->disk->signature==0x41543332 && v->start>=0 && v->sectors>=3 &&
    v->start<v->disk->sectors && v->sectors<=v->disk->sectors-v->start &&
    v->first>v->start && v->first<v->start+v->sectors &&
    v->root>=v->first && v->root<v->start+v->sectors;
}
Bool I386RedSeaExtent(CI386RedSea *v,I64 block,I64 size)
{
  I64 end=v->start+v->sectors;
  if (size<0 || size>(end-v->first)*512) return FALSE;
  if (!size && !block) return TRUE;
  return block>=v->first && block<end && (size+511)/512<=end-block;
}
Bool I386RedSeaDecode(CI386RedSea *v,U8 *raw,CI386RedSeaEntry *entry)
{
  I64 i,block=I386RedSeaWord(raw+40),size=I386RedSeaWord(raw+48);
  U16 attr=raw[0]|(raw[1]<<8);
  if (!(attr&0x800) || (attr&0x300) || !raw[2] ||
      !I386RedSeaExtent(v,block,size)) return FALSE;
  i=0;
  while (i<38 && raw[2+i]) i++;
  if (i==38) return FALSE;
  entry->attr=attr;
  for (i=0;i<38;i++) entry->name[i]=raw[2+i];
  entry->block=block; entry->size=size; entry->datetime=I386RedSeaWord(raw+56);
  return TRUE;
}
Bool I386RedSeaDirectory(CI386RedSea *v,I64 block,U8 *sector,I64 *size)
{
  CI386RedSeaEntry self;
  if (!I386RedSeaExtent(v,block,512) || !I386AtaRead(v->disk,block,sector) ||
      !I386RedSeaDecode(v,sector,&self) || !(self.attr&0x10) ||
      self.name[0]!='.' || self.name[1] || self.block!=block ||
      self.size<512 || (self.size&511)) return FALSE;
  *size=self.size;
  return TRUE;
}
public Bool I386RedSeaMount(CI386RedSea *volume,CI386Ata *disk,I64 start)
{//Caller owns a quiescent ATA channel with IF clear. Absolute disk addresses.
  CI386RedSea v;
  U8 sector[512];
  I64 sectors,bitmap,root,size,i;
  U8 *src,*dst;
  if (!volume || !disk || start<0 || !I386AtaRead(disk,start,sector) ||
      sector[3]!=0x88 || sector[510]!=0x55 || sector[511]!=0xAA ||
      I386RedSeaWord(sector+8)!=start) return FALSE;
  sectors=I386RedSeaWord(sector+16); root=I386RedSeaWord(sector+24);
  bitmap=I386RedSeaWord(sector+32);
  if (sectors<3 || sectors>disk->sectors-start || bitmap<1 || bitmap>=sectors-1 ||
      bitmap<(sectors+4095)/4096) return FALSE;
  v.disk=disk; v.signature=0x52533332; v.start=start; v.sectors=sectors;
  v.first=start+bitmap+1; v.root=root;
  if (!I386RedSeaValid(&v) || !I386RedSeaDirectory(&v,root,sector,&size)) return FALSE;
  src=&v; dst=volume;
  for (i=0;i<sizeof(CI386RedSea);i++) dst[i]=src[i];
  return TRUE;
}
public I64 I386RedSeaFind(CI386RedSea *volume,I64 directory,U8 *name,CI386RedSeaEntry *entry)
{//1 found, 0 absent, -1 invalid or I/O failure; output unchanged unless found.
  U8 sector[512],*raw;
  CI386RedSeaEntry found;
  I64 size,index,i,length=0;
  U8 *src,*dst;
  if (!I386RedSeaValid(volume) || !name || !entry) return -1;
  while (length<38 && name[length]) length++;
  if (!length || length==38 || !I386RedSeaDirectory(volume,directory,sector,&size)) return -1;
  for (index=0;index<size/64;index++) {
    if (!(index&7) && index && !I386AtaRead(volume->disk,directory+index/8,sector)) return -1;
    raw=sector+(index&7)*64;
    if (!raw[2]) return 0;
    if (!(raw[1]&1)) {
      if (!I386RedSeaDecode(volume,raw,&found)) return -1;
      i=0;
      while (i<length && found.name[i]==name[i]) i++;
      if (i==length && !found.name[i]) {
        src=&found; dst=entry;
        for (i=0;i<sizeof(CI386RedSeaEntry);i++) dst[i]=src[i];
        return 1;
      }
    }
  }
  return 0;
}
public I64 I386RedSeaRead(CI386RedSea *volume,CI386RedSeaEntry *entry,I64 offset,U8 *buffer,I64 count)
{//Raw bytes, including compressed files. Returns bytes copied; -1 before any data.
  U8 sector[512];
  I64 copied=0,n,i;
  if (!I386RedSeaValid(volume) || !entry || !buffer || offset<0 || count<0 ||
      (entry->attr&0x310) || !(entry->attr&0x800) ||
      !I386RedSeaExtent(volume,entry->block,entry->size) || offset>entry->size) return -1;
  if (count>entry->size-offset) count=entry->size-offset;
  if (count>0xFFFFFFFF || (buffer+0)(U64)>0x100000000-count) return -1;
  while (copied<count) {
    if (!I386AtaRead(volume->disk,entry->block+offset/512,sector)) {
      if (!copied) return -1;
      return copied;
    }
    n=512-(offset&511);
    if (n>count-copied) n=count-copied;
    for (i=0;i<n;i++) buffer[copied+i]=sector[(offset&511)+i];
    copied+=n; offset+=n;
  }
  return copied;
}

public I64 I386RedSeaResolve(CI386RedSea *volume,I64 directory,U8 *path,CI386RedSeaEntry *entry)
{//Volume-scoped slash paths. Output changes only on success; no drive syntax.
  CI386RedSeaEntry found; U8 name[38],*src,*dst; I64 length,result,i;
  if(!I386RedSeaValid(volume) || !path || !*path || !entry) return -1;
  if(*path=='/') directory=volume->root;
  while(*path=='/') path++;
  if(!*path) return I386RedSeaFind(volume,directory,".",entry);
  while(TRUE) {
    length=0;
    while(*path && *path!='/') {
      if(length==37 || *path==':' || *path==92) return -1;
      name[length++]=*path++;
    }
    name[length]=0;
    result=I386RedSeaFind(volume,directory,name,&found);
    if(result!=1) return result;
    if(name[0]=='.' && name[1]=='.' && !name[2]) {
      if(!(found.attr&0x10)) return -1;
      result=I386RedSeaFind(volume,found.block,".",&found);
      if(result!=1) return result;
    }
    if(*path) {
      if(!(found.attr&0x10)) return -1;
      while(*path=='/') path++;
      if(*path) { directory=found.block; }
      else break;
    } else break;
  }
  src=&found; dst=entry;
  for(i=0;i<sizeof(CI386RedSeaEntry);i++) dst[i]=src[i];
  return 1;
}
