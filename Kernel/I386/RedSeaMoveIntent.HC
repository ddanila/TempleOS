#include "/Kernel/I386/RedSea.HH"

#define I386_REDSEA_MOVE_MAGIC 0x3145564F4D323349
#define I386_REDSEA_MOVE_OFFSET 48
#define I386_REDSEA_MOVE_END 192

U64 I386RedSeaMoveChecksum(U8 *raw)
{
  U64 value=0xCBF29CE484222325;
  I64 i;
  for(i=56;i<184;i++) { value^=raw[i]; value*=0x100000001B3; }
  return value;
}

Bool I386RedSeaMoveHeader(CI386RedSea *v,U8 *raw)
{
  return I386RedSeaValid(v) && I386RedSeaSectorRead(v,v->start,raw) &&
    I386RedSeaWord(raw+8)==v->start && I386RedSeaWord(raw+16)==v->sectors;
}

public Bool I386RedSeaMoveIntentSet(CI386RedSea *v,I64 source_parent,Bool source_root,
  U8 *source_name,I64 destination_parent,Bool destination_root,U8 *destination_name,
  CI386RedSeaEntry *source)
{//One volume-wide cross-directory move may be in flight.
  U8 raw[512];
  I64 i;
  if(!source || !source_name || !destination_name ||
     !I386RedSeaMoveHeader(v,raw)) return FALSE;
  for(i=I386_REDSEA_MOVE_OFFSET;i<I386_REDSEA_MOVE_END;i++) if(raw[i]) return FALSE;
  for(i=0;i<38 && source_name[i];i++); if(!i || i==38) return FALSE;
  for(i=0;i<38 && destination_name[i];i++); if(!i || i==38) return FALSE;
  if(source_root) I386RedSeaPutWord(raw+56,0);
  else I386RedSeaPutWord(raw+56,source_parent);
  if(destination_root) I386RedSeaPutWord(raw+64,0);
  else I386RedSeaPutWord(raw+64,destination_parent);
  I386RedSeaPutWord(raw+72,source->block);
  I386RedSeaPutWord(raw+80,source->size);
  I386RedSeaPutWord(raw+88,source->datetime);
  I386RedSeaPutWord(raw+96,source->attr);
  for(i=0;i<76;i++) raw[104+i]=0;
  i=0; while(source_name[i]) { raw[104+i]=source_name[i]; i++; }
  i=0; while(destination_name[i]) { raw[142+i]=destination_name[i]; i++; }
  I386RedSeaPutWord(raw+184,I386RedSeaMoveChecksum(raw));
  I386RedSeaPutWord(raw+48,I386_REDSEA_MOVE_MAGIC);
  if(!I386RedSeaSectorWrite(v,v->start,raw) || !I386RedSeaFlush(v)) {
    v->signature=0; return FALSE;
  }
  return TRUE;
}

public Bool I386RedSeaMoveIntentClear(CI386RedSea *v)
{
  U8 raw[512];
  I64 i;
  if(!I386RedSeaMoveHeader(v,raw) || I386RedSeaWord(raw+48)!=I386_REDSEA_MOVE_MAGIC ||
     I386RedSeaWord(raw+184)!=I386RedSeaMoveChecksum(raw)) return FALSE;
  for(i=I386_REDSEA_MOVE_OFFSET;i<I386_REDSEA_MOVE_END;i++) raw[i]=0;
  if(!I386RedSeaSectorWrite(v,v->start,raw) || !I386RedSeaFlush(v)) {
    v->signature=0; return FALSE;
  }
  return TRUE;
}

Bool I386RedSeaMoveRecoveryDelete(CI386RedSea *v,I64 directory,U8 *name)
{
  U8 sector[512],*entry;
  CI386RedSeaEntry found;
  I64 size,index,i,blocks;
  if(I386RedSeaFind(v,directory,name,&found)!=1 || (found.attr&0x11) ||
     !I386RedSeaDirectory(v,directory,sector,&size)) return FALSE;
  for(index=0;index<size/64;index++) {
    if(!(index&7) && index && !I386RedSeaSectorRead(v,directory+index/8,sector)) return FALSE;
    entry=sector+(index&7)*64;
    if(!entry[2]) return FALSE;
    if(!(entry[1]&1)) {
      i=0; while(i<38 && entry[2+i]==name[i]) { if(!name[i]) break; i++; }
      if(i<38 && !name[i] && !entry[2+i]) {
        entry[1]|=1;
        if(!I386RedSeaSectorWrite(v,directory+index/8,sector) || !I386RedSeaFlush(v)) return FALSE;
        blocks=(found.size+511)/512;
        if(blocks && (!I386RedSeaFree(v,found.block,blocks) || !I386RedSeaFlush(v))) return FALSE;
        return TRUE;
      }
    }
  }
  return FALSE;
}

Bool I386RedSeaMoveRecover(CI386RedSea *v)
{//Rollback a published duplicate while the source exists; otherwise accept commit.
  U8 raw[512],source_name[38],destination_name[38];
  CI386RedSeaEntry source,destination;
  I64 source_parent,destination_parent,source_status,destination_status,i;
  if(!I386RedSeaMoveHeader(v,raw)) return FALSE;
  if(!I386RedSeaWord(raw+48)) {
    for(i=I386_REDSEA_MOVE_OFFSET;i<I386_REDSEA_MOVE_END;i++) if(raw[i]) return FALSE;
    return TRUE;
  }
  if(I386RedSeaWord(raw+48)!=I386_REDSEA_MOVE_MAGIC ||
     I386RedSeaWord(raw+184)!=I386RedSeaMoveChecksum(raw)) return FALSE;
  source_parent=I386RedSeaWord(raw+56); if(!source_parent) source_parent=v->root;
  destination_parent=I386RedSeaWord(raw+64); if(!destination_parent) destination_parent=v->root;
  for(i=0;i<38;i++) { source_name[i]=raw[104+i]; destination_name[i]=raw[142+i]; }
  if(!source_name[0] || !destination_name[0]) return FALSE;
  source_status=I386RedSeaFind(v,source_parent,source_name,&source);
  destination_status=I386RedSeaFind(v,destination_parent,destination_name,&destination);
  if(source_status<0 || destination_status<0 || (!source_status && !destination_status)) return FALSE;
  if(source_status && (source.block!=I386RedSeaWord(raw+72) ||
     source.size!=I386RedSeaWord(raw+80) || source.datetime!=I386RedSeaWord(raw+88) ||
     source.attr!=I386RedSeaWord(raw+96))) return FALSE;
  if(destination_status && (destination.size!=I386RedSeaWord(raw+80) ||
     destination.datetime!=I386RedSeaWord(raw+88) ||
     destination.attr!=I386RedSeaWord(raw+96))) return FALSE;
  if(source_status && destination_status &&
     !I386RedSeaMoveRecoveryDelete(v,destination_parent,destination_name)) return FALSE;
  return I386RedSeaMoveIntentClear(v);
}
