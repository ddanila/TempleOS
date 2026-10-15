//Identity of the clean backing image currently uploaded to VGA.
U8 *native_display_planes[4];
I64 native_display_epoch;
Bool NativeDisplayViewMatches(U8 **planes)
{
  I64 p;
  if(!planes || !planes[0])return FALSE;
  for(p=0;p<4;p++)if(planes[p]!=native_display_planes[p])return FALSE;
  return TRUE;
}
U0 NativeDisplayViewCommit(U8 **planes)
{//Caller owns display access. NULL denotes an unretained temporary image.
  I64 p;
  for(p=0;p<4;p++) {
    if(planes)native_display_planes[p]=planes[p];
    else native_display_planes[p]=NULL;
  }
  native_display_epoch++;
}
