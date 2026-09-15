//Original non-debug allocation records; caller supplies CHeapCtrl.
class CMemUnused
{
  U0	hc;
  U0	caller1,caller2;
  CMemUnused *next;
  I64	size;
};
class CMemUsed
{
  CHeapCtrl *hc;
  U0	caller1,caller2;
  U0	next,last;
  I64	size;
  U0	start;
};
