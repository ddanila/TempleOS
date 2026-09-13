#ifndef I386_SCAN_SET1_INCLUDED
#define I386_SCAN_SET1_INCLUDED
class CI386ScanSet1 { U32 extended,pause; };
public extern U0 I386ScanSet1Reset(CI386ScanSet1 *state);
public extern I64 I386ScanSet1Feed(CI386ScanSet1 *state,U8 data,U8 status,U32 *scan);
#endif
