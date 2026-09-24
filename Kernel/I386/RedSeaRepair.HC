#include "/Kernel/I386/RedSea.HH"

Bool I386RedSeaRepairDecode(CI386RedSea *v,U8 *raw,CI386RedSeaEntry *entry)
{
  I64 i,block=0,size=0;
  U16 attr=raw[0]|(raw[1]<<8);
  for(i=0;i<8;i++) { block|=(raw[40+i]+0)(U64)<<(8*i); size|=(raw[48+i]+0)(U64)<<(8*i); }
  if(!(attr&0x800) || (attr&0x300) || !raw[2] ||
     (size<0 || size>(v->start+v->sectors-v->first)*512) ||
     (size && (block<v->first || block>=v->start+v->sectors ||
      (size+511)/512>v->start+v->sectors-block)) ||
     (!size && block && (block<v->first || block>=v->start+v->sectors))) return FALSE;
  i=0; while(i<38 && raw[2+i]) i++;
  if(i==38) return FALSE;
  entry->attr=attr;
  for(i=0;i<38;i++) entry->name[i]=raw[2+i];
  entry->block=block; entry->size=size;
  entry->datetime=0; for(i=0;i<8;i++) entry->datetime|=(raw[56+i]+0)(U64)<<(8*i);
  return TRUE;
}

Bool I386RedSeaRepairClaim(CI386RedSea *v,U8 *bits,I64 bytes,I64 block,I64 size)
{
  I64 count,index,i;
  if(!size && !block) return TRUE;
  if(size<=0 || block<v->first || block>=v->start+v->sectors) return FALSE;
  count=(size+511)/512;
  if(count>v->start+v->sectors-block) return FALSE;
  for(i=0;i<count;i++) {
    index=block+i-(v->first-1);
    if(index<1 || index>=bytes*8 || bits[index>>3]&(1<<(index&7))) return FALSE;
    bits[index>>3]|=1<<(index&7);
  }
  return TRUE;
}

Bool I386RedSeaRepairDirectory(CI386RedSea *v,U8 *bits,I64 bytes,I64 block,I64 parent,I64 expected_size)
{
  U8 sector[512],*raw;
  CI386RedSeaEntry self,up,entry;
  I64 size,index,i;
  U16 attr;
  if(!I386RedSeaDirectory(v,block,sector,&size) ||
     (expected_size && size!=expected_size) ||
     !I386RedSeaRepairClaim(v,bits,bytes,block,size) ||
     !I386RedSeaRepairDecode(v,sector,&self) || self.block!=block || self.size!=size ||
     !I386RedSeaRepairDecode(v,sector+64,&up) || !(up.attr&0x10) ||
     up.name[0]!='.' || up.name[1]!='.' || up.name[2] || up.block!=parent) return FALSE;
  for(index=2;index<size/64;index++) {
    if(!(index&7) && !I386RedSeaSectorRead(v,block+index/8,sector)) return FALSE;
    raw=sector+(index&7)*64;
    if(!raw[2]) return TRUE;
    if(!(raw[1]&1)) {
      attr=raw[0]|(raw[1]<<8);
      if(!(attr&0x800) || (attr&0x300) || raw[2]=='.') return FALSE;
      i=0; while(i<38 && raw[2+i]) i++;
      if(!i || i==38) return FALSE;
      entry.attr=attr; entry.block=0; entry.size=0;
      for(i=0;i<8;i++) {
        entry.block|=(raw[40+i]+0)(U64)<<(8*i);
        entry.size|=(raw[48+i]+0)(U64)<<(8*i);
      }
      if(entry.attr&0x10) {
        if(entry.size<=0 ||
           !I386RedSeaRepairDirectory(v,bits,bytes,entry.block,block,entry.size)) return FALSE;
      } else if(!I386RedSeaRepairClaim(v,bits,bytes,entry.block,entry.size)) return FALSE;
    }
  }
  return FALSE;
}

Bool I386RedSeaRepairBitmap(CI386RedSea *v,U8 *scratch,I64 bytes)
{//Rebuild allocation truth from the reachable namespace before task I/O is bound.
  U8 actual[512],*expected;
  I64 required,sector,index,block,valid_bits;
  Bool changed=FALSE,different;
  if(!I386RedSeaValid(v) || v->io || !scratch) return FALSE;
  required=(v->first-v->start-1)*512;
  if(bytes!=required || bytes<=0) return FALSE;
  for(index=0;index<bytes;index++) scratch[index]=0;
  scratch[0]|=1;
  valid_bits=v->start+v->sectors-(v->first-1);
  for(index=valid_bits;index<bytes*8;index++) scratch[index>>3]|=1<<(index&7);
  if(!I386RedSeaRepairDirectory(v,scratch,bytes,v->root,v->root,0)) return FALSE;
  for(sector=0;sector<required/512;sector++) {
    block=v->start+1+sector; expected=scratch+sector*512;
    if(!I386RedSeaSectorRead(v,block,actual)) return FALSE;
    different=FALSE;
    for(index=0;index<512;index++) if(actual[index]!=expected[index]) {
      different=TRUE; break;
    }
    if(different) {
      changed=TRUE;
      if(!I386RedSeaSectorWrite(v,block,expected)) return FALSE;
    }
  }
  if(changed && !I386RedSeaFlush(v)) return FALSE;
  return TRUE;
}
