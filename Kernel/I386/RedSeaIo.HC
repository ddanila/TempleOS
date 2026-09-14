#include "/Kernel/I386/RedSea.HH"
Bool I386RedSeaBegin(CI386RedSea *volume)
{
  if(!I386RedSeaValid(volume)) return FALSE;
  if(!volume->io) return TRUE;
  if(!volume->io->begin) return FALSE;
  return (*volume->io->begin)(volume->io->context);
}
Bool I386RedSeaEnd(CI386RedSea *volume)
{
  if(!volume) return FALSE;
  if(!volume->io) return TRUE;
  if(!volume->io->end) return FALSE;
  return (*volume->io->end)(volume->io->context);
}
Bool I386RedSeaSectorRead(CI386RedSea *volume,I64 block,U8 *buffer)
{
  if(!volume) return FALSE;
  if(!volume->io) return I386AtaRead(volume->disk,block,buffer);
  if(!volume->io->read) return FALSE;
  return (*volume->io->read)(volume->io->context,volume->disk,block,buffer);
}
Bool I386RedSeaSectorWrite(CI386RedSea *volume,I64 block,U8 *buffer)
{
  if(!volume) return FALSE;
  if(!volume->io) return I386AtaWrite(volume->disk,block,buffer);
  if(!volume->io->write) return FALSE;
  return (*volume->io->write)(volume->io->context,volume->disk,block,buffer);
}
Bool I386RedSeaFlush(CI386RedSea *volume)
{
  if(!volume) return FALSE;
  if(!volume->io) return I386AtaFlush(volume->disk);
  if(!volume->io->flush) return FALSE;
  return (*volume->io->flush)(volume->io->context,volume->disk);
}
