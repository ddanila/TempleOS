U8 *ToggleZorNotZ(U8 *name)
{//MAlloc name with Z if not Z or vice versa.
  I64 size=StrLen(name)+3;
  if(IsDotZ(name)) size-=2;
  return FileNameWriteToggle(MAlloc(size),name);
}
