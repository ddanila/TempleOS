//Original debug allocation records; caller supplies CHeapCtrl.
class CMemUnused
{
  CHeapCtrl *hc;
  U8	*caller1,*caller2;
  CMemUnused *next;
  I64	size;
};
class CMemUsed
{
  CHeapCtrl *hc;
  U8	*caller1,*caller2;
  CMemUsed *next,*last;
  I64	size;
  U0	start;
};
