I64 FileExtensionContract()
{
  I64 mask=0,base=Fs->data_heap->used_u8s;
  U8 *p,*q,a[64],b[64];
  StrCpy(a,"C:/one.two/file.HC.Z");p=FileExtDot(a);
  if(p==a+6 && !StrCmp(p,".two/file.HC.Z") && !FileExtDot("C:/dir/file") &&
     !FileExtDot("C:/../file"))mask|=1;
  StrCpy(a,"C:/Dir/Name.HC.Z");p=FileExtRem(a,b);
  if(p==b && !StrCmp(a,"C:/Dir/Name") && !StrCmp(b,"HC.Z"))mask|=2;
  StrCpy(a,"C:/NoExt");StrCpy(b,"old");p=FileExtRem(a,b);
  if(p==b && !StrCmp(a,"C:/NoExt") && !*b && !FileExtRem(a))mask|=4;
  p=ExtChg("C:/Dir/Name.HC.Z","TXT");q=ExtChg("NoExt","HC");
  if(!StrCmp(p,"C:/Dir/Name.TXT") && !StrCmp(q,"NoExt.HC"))mask|=8;
  Free(p);Free(q);
  if(IsDotC("file.HC.C") && !IsDotC("file.C") && !IsDotC("file.HC.c") &&
     IsDotZ("file.HC.Z") && !IsDotZ("file.Z") && !IsDotZ("file.HC.z"))mask|=16;
  p=ToggleZorNotZ("file.HC.Z");q=ToggleZorNotZ("file.Z");
  if(!StrCmp(p,"file.HC") && !StrCmp(q,"file.Z.Z"))mask|=32;
  Free(p);Free(q);
  if(Fs->data_heap->used_u8s==base)mask|=64;
  return mask;
}
