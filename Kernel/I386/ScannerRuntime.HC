#include "/Kernel/DisplayableBitmap.HH"
U32 char_bmp_displayable[16]=CHAR_BMP_DISPLAYABLE_DATA;
//Retain every original scan format, including date conversion.
#include "/Kernel/StringUtilFlags.HH"
import U32 char_bmp_dec_numeric[16];
U32 char_bmp_white_space[16]={0x80002600,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
U32 char_bmp_safe_dollar[16]={
  0x80000000,0xFFFFFFEF,0xFFFFFFFF,0x7FFFFFFF,
  0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,0xFFFFFFFF,
  0,0,0,0,0,0,0,0
};
I64 NativeScanStrNCmp(U8 *left,U8 *right,I64 count)
{
  while(count-->0) {
    if(*left<*right) return -1;
    if(*left>*right) return 1;
    if(!*left) return 0;
    left++;right++;
  }
  return 0;
}
#include "/Kernel/StringUtilCore.HC"
#include "/Kernel/StringAllocUtilCore.HC"
#include "/Kernel/StringTailCore.HC"
#define StrNCmp NativeScanStrNCmp
#define Now NativeNow
#include "/Kernel/StrScanCore.HC"
//These aliases remain private to the retained module compilation.
