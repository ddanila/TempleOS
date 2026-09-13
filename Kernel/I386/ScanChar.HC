#include "/Kernel/I386/ScanChar.HH"
public U8 I386ScanCode2Char(I64 scan)
{//Match the existing TempleOS character tables; caller supplies mapped scan flags.
  I64 code=scan&0x7F;
  Bool shift=FALSE,ctrl=FALSE;
  U8 ch=0;
  U8 *table;
  if ((scan&0x80) || code>=0x50) return 0;
  if (scan&0x400) ctrl=TRUE;
  else if (((scan>>9)^(scan>>12))&1) shift=TRUE;
  if (code==1) { if (shift) return 0x1C; return 0x1B; }
  if (code==0x0E) return 8;
  if (code==0x0F) return 9;
  if (code==0x1C) return 10;
  if (code==0x39) { if (shift) return 0x1F; return 32; }
  if (code==0x37) return '*';
  if (code==0x4A) return '-';
  if (code==0x4E) return '+';
  if (code>=2 && code<=0x0D) {
    table="1234567890-=";
    if (shift) { if (code==5) return 36; table="!@# %^&*()_+"; }
    ch=table[code-2];
  }
  if (code>=0x10 && code<=0x1B) {
    table="qwertyuiop[]";
    if (shift) table="QWERTYUIOP{}";
    ch=table[code-0x10];
  }
  if (code>=0x1E && code<=0x28) {
    table="asdfghjkl;'";
    if (shift) table="ASDFGHJKL:\"";
    ch=table[code-0x1E];
  }
  if (code==0x29) { if (shift) return '~'; return 0x60; }
  if (code>=0x2B && code<=0x35) {
    table="\\zxcvbnm,./";
    if (shift) table="|ZXCVBNM<>?";
    ch=table[code-0x2B];
  }
  if (ctrl && ch>='a' && ch<='z') ch=ch-'a'+1;
  return ch;
}
