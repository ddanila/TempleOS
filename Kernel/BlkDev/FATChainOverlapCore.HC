I64 FAT32ChainOverlap(CDrv *dv,I64 old_clus,I64 new_clus)
{// Singly linked FAT chains share a suffix if and only if their tails match.
  I64 a,b,limit,old_count=0,new_count=0,old_tail=INVALID_CLUS,new_tail=INVALID_CLUS;
  if (dv->spc<=0) throw('FAT');
  limit=dv->size/dv->spc+1;
  a=old_clus;
  while (0<a<0x0FFFFFF8) {
    old_tail=a;
    if (++old_count>limit) throw('FAT');
    a=ClusNumNext(dv,a);
  }
  b=new_clus;
  while (0<b<0x0FFFFFF8) {
    new_tail=b;
    if (++new_count>limit) throw('FAT');
    b=ClusNumNext(dv,b);
  }
  if (!old_count || !new_count || old_tail!=new_tail) return INVALID_CLUS;
  a=old_clus;
  b=new_clus;
  while (old_count>new_count) {
    a=ClusNumNext(dv,a);
    old_count--;
  }
  while (new_count>old_count) {
    b=ClusNumNext(dv,b);
    new_count--;
  }
  while (a!=b) {
    a=ClusNumNext(dv,a);
    b=ClusNumNext(dv,b);
  }
  return a;
}
