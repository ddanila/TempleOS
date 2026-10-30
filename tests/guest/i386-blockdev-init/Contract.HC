extern Bool BlkDevInit(CBlkDev *bd);
I64 BIContract()
{
  CBlkDev copy,*live=Fs->cur_dv->bd;
  I64 mask=0,flags=live->flags;
  if(BlkDevInit(live) && live->flags==flags)mask|=1;
  MemCpy(&copy,live,sizeof(CBlkDev));
  copy.type=255;
  copy.flags&=~(BDF_INITIALIZED|BDF_INIT_IN_PROGRESS|BDF_READ_CACHE);
  if(!BlkDevInit(&copy) && copy.flags&BDF_INITIALIZED &&
      !(copy.flags&BDF_INIT_IN_PROGRESS))mask|=2;
  flags=copy.flags;
  if(BlkDevInit(&copy) && copy.flags==flags)mask|=4;
  return mask;
}
