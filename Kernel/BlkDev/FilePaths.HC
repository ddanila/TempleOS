#include "/Kernel/BlkDev/FilePaths.HH"
U0 FilePathCopy(U8 *dst,U8 *src)
{
  if(src) while(*src) *dst++=*src++;
  *dst=0;
}
I64 FilePathCapacity(U8 *name,CFilePathContext *context)
{
  I64 size=FileNameLength(name)+5;
  if(context->cur_dir) size+=FileNameLength(context->cur_dir);
  if(context->home_dir) size+=FileNameLength(context->home_dir);
  return size;
}
Bool FilePathSpace(CFilePathContext *context,I64 ch)
{
  return (context->white_space[ch>>5]>>(ch&31))&1;
}
U0 FilePathClean(U8 *work,CFilePathContext *context)
{//The three original StrUtil flags, including the first-byte trailing rule.
  U8 *src=work,*dst=work;
  I64 ch;
  while(FilePathSpace(context,*src)) src++;
  while(ch=*src++)
    if(FilePathSpace(context,ch) || ch>=31) *dst++=ch;
  *dst=0;
  while(dst!=work && (!*dst || FilePathSpace(context,*dst))) *dst--=0;
}
U8 *FilePathDirWrite(U8 *dst,U8 *work,CFilePathContext *context)
{
  U8 *part,*next,*path=dst+2,drive=context->cur_drv;
  I64 length,used;
  if(!context->cur_dir || !*context->cur_dir) {
    FilePathCopy(dst,work); return dst;
  }
  FilePathClean(work,context);
  if(*work && work[1]==':') {
    if(*work==':') drive=context->boot_drv;
    else if(*work=='~') drive=*context->home_dir;
    else drive=*work;
    work+=2; FilePathCopy(path,"/");
  } else FilePathCopy(path,context->cur_dir);
  if(*work=='/') { FilePathCopy(path,"/"); work++; }
  while(*work) {
    part=work; next=work;
    while(*next && *next!='/') next++;
    length=next-part;
    if(*next) { *next=0; next++; }
    if(!length) FilePathCopy(path,"/");
    else if(length==2 && part[0]=='.' && part[1]=='.') {
      used=FileNameLength(path);
      while(used && path[used-1]!='/') used--;
      if(used) used--;
      path[used]=0;
      if(!used) FilePathCopy(path,"/");
    } else if(length==1 && *part=='~') {
      FilePathCopy(path,context->home_dir+2); drive=*context->home_dir;
    } else if(length!=1 || *part!='.') {
      used=FileNameLength(path);
      if(used!=1 || *path!='/') path[used++]='/';
      FilePathCopy(path+used,part);
    }
    work=next;
  }
  dst[0]=drive; dst[1]=':';
  return dst;
}
U8 *FilePathFileWrite(U8 *dst,U8 *work,U8 *leaf,CFilePathContext *context)
{
  U8 *buf,*last=0,*scan;
  I64 used;
  Bool rooted;
  FilePathClean(work,context);
  buf=work;
  if(*buf && buf[1]==':') buf+=2;
  rooted=*buf=='/';
  for(scan=buf;*scan;scan++) if(*scan=='/') last=scan;
  if(last) { FilePathCopy(leaf,last+1); *last=0; }
  else { FilePathCopy(leaf,buf); *buf=0; }
  if(rooted && !*buf) FilePathCopy(buf,"/");
  FilePathDirWrite(dst,work,context);
  used=FileNameLength(dst);
  if(!used || dst[used-1]!='/') dst[used++]='/';
  FilePathCopy(dst+used,leaf);
  return dst;
}
