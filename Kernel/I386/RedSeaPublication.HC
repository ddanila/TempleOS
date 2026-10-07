#include "/Kernel/I386/RedSeaPublication.HH"
#include "/Kernel/I386/ModulePublishCore.HC"
#include "/Kernel/I386/RedSeaSlot.HC"
Bool I386RedSeaPublicationEqual(U8 *a,U8 *b)
{U32 i;for(i=0;i<64;i++)if(a[i]!=b[i])return FALSE;return TRUE;}
Bool I386RedSeaPublicationFlush(U8 *context)
{CI386RedSeaPublication *p=context;return I386RedSeaFlush(p->volume);}
Bool I386RedSeaPublicationWrite(U8 *context)
{
  CI386RedSeaPublication *p=context;
  U8 sector[512],*slot;U32 i;
  if(!I386RedSeaSectorRead(p->volume,p->sector,sector))return FALSE;
  slot=sector+p->slot*64;
  if(!I386RedSeaPublicationEqual(slot,p->before))return FALSE;
  for(i=0;i<64;i++)slot[i]=p->after[i];
  return I386RedSeaSectorWrite(p->volume,p->sector,sector);
}
U32 I386RedSeaPublicationObserve(U8 *context)
{
  CI386RedSeaPublication *p=context;
  U8 sector[512],*slot;
  if(!I386RedSeaSectorRead(p->volume,p->sector,sector))return 0;
  slot=sector+p->slot*64;
  if(I386RedSeaPublicationEqual(slot,p->after))return I386_PUBLISH_NEW;
  if(I386RedSeaPublicationEqual(slot,p->before))return I386_PUBLISH_OLD;
  return 0;
}
Bool I386RedSeaPublicationReclaim(U8 *context)
{
  CI386RedSeaPublication *p=context;
  if(!p->old_blocks)return TRUE;
  if(!I386RedSeaReleaseOwned(p->volume,p->old_block,p->old_blocks) ||
      !I386RedSeaFlush(p->volume))return FALSE;
  p->old_block=p->old_blocks=0;return TRUE;
}
Bool I386RedSeaPublicationInit(CI386RedSeaPublication *p,CI386RedSea *volume,
  I64 sector,U32 slot,U8 *new_entry,I64 *owned_block)
{
  U8 buffer[512],*old;CI386RedSeaEntry fresh,prior;U32 i;
  I64 fresh_blocks,prior_blocks=0;
  if(!p || p->transaction.phase || !I386RedSeaValid(volume) ||
      !volume->disk->flush || slot>=8 || !new_entry || !owned_block ||
      *owned_block<=0 || sector<volume->first || sector>=volume->start+volume->sectors ||
      !I386RedSeaDecode(volume,new_entry,&fresh) || fresh.attr&0x11 ||
      fresh.block!=*owned_block || fresh.size<32)return FALSE;
  fresh_blocks=(fresh.size+511)/512;
  if(sector>=fresh.block && sector<fresh.block+fresh_blocks)return FALSE;
  if(!I386RedSeaSectorRead(volume,sector,buffer))return FALSE;
  old=buffer+slot*64;
  if(old[2] && !(old[1]&1)) {
    if(!I386RedSeaDecode(volume,old,&prior) || prior.attr&0x11)return FALSE;
    for(i=0;i<38;i++) {
      if(prior.name[i]!=fresh.name[i])return FALSE;
      if(!prior.name[i])break;
    }
    prior_blocks=(prior.size+511)/512;
    if(prior_blocks && fresh.block<prior.block+prior_blocks &&
        prior.block<fresh.block+fresh_blocks)return FALSE;
  }
  p->shared=p->volume=volume;p->sector=sector;p->slot=slot;
  p->old_blocks=prior_blocks;p->old_block=0;if(prior_blocks)p->old_block=prior.block;
  for(i=0;i<64;i++){p->before[i]=old[i];p->after[i]=new_entry[i];}
  return I386ModulePublishInit(&p->transaction,p,owned_block,
    &I386RedSeaPublicationFlush,&I386RedSeaPublicationWrite,
    &I386RedSeaPublicationObserve,&I386RedSeaPublicationReclaim);
}
Bool I386RedSeaPublicationCommit(CI386RedSeaPublication *p)
{
  Bool result;
  if(!p || !p->transaction.phase)return FALSE;
  result=I386ModulePublishCommit(&p->transaction);
  if(!result)p->shared->signature=0;
  return result;
}
I64 I386RedSeaPublicationPrepare(CI386RedSeaPublication *p,CI386RedSea *volume,
  I64 directory,U8 *name,I64 *owned_block,I64 size,I64 datetime=0)
{//Resolve replacement or prepare a free slot, including the existing growth path.
  U8 sector[512],entry[64],*raw;CI386RedSeaEntry existing,fresh;
  I64 status,dir_size,index,slot=-1,i;
  if(!p || p->transaction.phase || !owned_block || *owned_block<=0 || size<32 ||
      !I386RedSeaValid(volume) || !I386RedSeaNewName(name))return -1;
  for(i=0;i<64;i++)entry[i]=0;
  entry[1]=8;
  for(i=0;name[i];i++)entry[2+i]=name[i];
  I386RedSeaPutWord(entry+40,*owned_block);I386RedSeaPutWord(entry+48,size);
  I386RedSeaPutWord(entry+56,datetime);
  if(!volume->disk->flush || !I386RedSeaDecode(volume,entry,&fresh))return -1;
  status=I386RedSeaFind(volume,directory,name,&existing);
  if(status<0)return -1;
  if(status) {
    if(existing.attr&0x11 || !I386RedSeaDirectory(volume,directory,sector,&dir_size) ||
        sector[0]&1)return -1;
    for(index=2;index<dir_size/64;index++) {
      if(!(index&7) && !I386RedSeaSectorRead(volume,directory+index/8,sector))return -1;
      raw=sector+(index&7)*64;
      if(!raw[2])return -1;
      if(!(raw[1]&1)) {
        i=0;while(i<38 && raw[2+i]==name[i]){if(!name[i])break;i++;}
        if(i<38 && !name[i] && !raw[2+i]){slot=index;break;}
      }
    }
    if(slot<0)return -1;
  } else {
    status=I386RedSeaExtentSlot(volume,&directory,name,&slot);
    if(status!=1)return status;
    if(!I386RedSeaDirectory(volume,directory,sector,&dir_size) || slot<2 ||
        slot>=dir_size/64-1)return -1;
    //Ensure an append terminator is durable before the file can be published.
    if(!I386RedSeaSectorRead(volume,directory+slot/8,sector))return -1;
    raw=sector+(slot&7)*64;
    if(!raw[2]) {
      index=slot+1;
      if(!I386RedSeaSectorRead(volume,directory+index/8,sector))return -1;
      for(i=0;i<64;i++)sector[(index&7)*64+i]=0;
      if(!I386RedSeaSectorWrite(volume,directory+index/8,sector) ||
          !I386RedSeaFlush(volume)){volume->signature=0;return -1;}
    }
  }
  if(!I386RedSeaPublicationInit(p,volume,directory+slot/8,slot&7,entry,owned_block))return -1;
  return 1;
}
Bool I386RedSeaPublicationRecover(CI386RedSeaPublication *p)
{
  Bool result;CI386RedSeaIo *io;
  if(!p || !p->transaction.phase)return FALSE;
  if(!I386RedSeaValid(p->shared)) {
    io=p->shared->io;
    //Persistent private view: a blocked operation must not borrow a stack mount.
    if(!I386RedSeaMount(&p->private_volume,p->shared->disk,p->shared->start))return FALSE;
    p->private_volume.io=io;p->volume=&p->private_volume;
  }
  result=I386ModulePublishRecover(&p->transaction);
  if(!result)p->shared->signature=0;
  return result;
}
