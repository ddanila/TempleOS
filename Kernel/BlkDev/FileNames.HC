#include "/Kernel/BlkDev/FileNames.HH"
U8 *FileExtDot(U8 *src)
{//Preserve whole-path scanning, including dots before directory separators.
  I64 ch;
  while(ch=*src++)
    if(ch=='.' && *src!='/' && *src!='.') return src-1;
  return 0;
}
I64 FileNameLength(U8 *name)
{
  I64 length=0;
  while(name[length]) length++;
  return length;
}
Bool FileNameDotSuffix(U8 *name,I64 suffix)
{
  I64 length=0,dots=0;
  while(name[length]) {
    if(name[length]=='.') dots++;
    length++;
  }
  return dots>1 && name[length-1]==suffix && name[length-2]=='.';
}
Bool IsDotZ(U8 *filename) { return FileNameDotSuffix(filename,'Z'); }
Bool IsDotC(U8 *filename) { return FileNameDotSuffix(filename,'C'); }
U8 *FileNameWriteDefault(U8 *dst,U8 *name,U8 *extension)
{
  I64 i=0,j=0;
  while(name[i]) { dst[i]=name[i]; i++; }
  if(!FileExtDot(name)) {
    dst[i++]='.';
    while(extension[j]) dst[i++]=extension[j++];
  }
  dst[i]=0;
  return dst;
}
U8 *FileNameWriteToggle(U8 *dst,U8 *name)
{
  I64 length=FileNameLength(name),i;
  Bool compressed=IsDotZ(name);
  if(compressed) length-=2;
  for(i=0;i<length;i++) dst[i]=name[i];
  if(!compressed) { dst[i++]='.'; dst[i++]='Z'; }
  dst[i]=0;
  return dst;
}
