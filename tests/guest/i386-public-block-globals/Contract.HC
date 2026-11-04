extern CBlkDevGlbls *I386DskCacheGlobals();
_extern NativeBlockRecords CBlkDev *PublicBlockRecords;
U0 PublicBlockGlobalsContract()
{
  CBlkDevGlbls *g=I386DskCacheGlobals;
  I64 r=g->read_cnt,w=g->write_cnt;
  if(&blkdev!=g||blkdev.blkdevs!=PublicBlockRecords)throw('BlkGlbl',TRUE);
  if(blkdev.let_to_drv['C'-'A']!=Let2Drv('C'))throw('BlkGlbl',TRUE);
  blkdev.read_cnt=r+37;
  if(g->read_cnt!=r+37)throw('BlkGlbl',TRUE);
  g->write_cnt=w+73;
  if(blkdev.write_cnt!=w+73)throw('BlkGlbl',TRUE);
  blkdev.read_cnt=r;blkdev.write_cnt=w;
}
PublicBlockGlobalsContract;
