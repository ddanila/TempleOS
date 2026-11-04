#help_index "File/Internal"
I64 DirTreeSerializeSize(CDirEntry *tmpde)
{
  I64 res=0;
  while (tmpde) {
    res+=CDIR_SIZE+1;
    if (tmpde->attr & RS_ATTR_DIR)
      res+=DirTreeSerializeSize(tmpde->sub);
    tmpde=tmpde->next;
  }
  return res+1;
}
I64 DirTreeSerializeFill(CDirEntry *tmpde,U8 *dst)
{
  I64 res=0,i;
  while (tmpde) {
    *dst++=1;
    res++;
    MemCpy(dst,&tmpde->start,CDIR_SIZE);
    dst+=CDIR_SIZE;
    res+=CDIR_SIZE;
    if (tmpde->attr & RS_ATTR_DIR) {
      i=DirTreeSerializeFill(tmpde->sub,dst);
      dst+=i;
      res+=i;
    }
    tmpde=tmpde->next;
  }
  *dst=0;
  return res+1;
}
public U8 *DirTreeSerialize(CDirEntry *tmpde,I64 *_size=NULL)
{//Serialize tree returned from $LK,"FilesFind",A="MN:FilesFind"$() into a one contiguous U8 array.
  I64 size=DirTreeSerializeSize(tmpde);
  U8 *buf=MAlloc(size);
  DirTreeSerializeFill(tmpde,buf);
  if (_size) *_size=size;
  return buf;
}

U8 *DirTreeUnserialize2(U8 *src,CDirEntry **tmpde)
{
  CDirEntry *tmpde1;
  if (*src++) {
    tmpde1=CAlloc(sizeof(CDirEntry));
    *tmpde=tmpde1;
    MemCpy(&tmpde1->start,src,CDIR_SIZE);
    src+=CDIR_SIZE;
    if (tmpde1->attr & RS_ATTR_DIR)
      src=DirTreeUnserialize2(src,&tmpde1->sub);
    src=DirTreeUnserialize2(src,&tmpde1->next);
  } else
    *tmpde=NULL;
  return src;
}
public CDirEntry *DirTreeUnserialize(U8 *src)
{//Unserialize tree to make it like a tree returned from $LK,"FilesFind",A="MN:FilesFind"$().
  CDirEntry *tmpde=NULL;
  DirTreeUnserialize2(src,&tmpde);
  return tmpde;
}

#help_index "File/Program Routines"
U0 FOFlatten(CDirEntry *tmpde,CDirEntry **a,I64 *i)
{
  CDirEntry *tmpde1;
  while (tmpde) {
    tmpde1=tmpde->next;
    if (tmpde->attr&RS_ATTR_DIR) {
      FOFlatten(tmpde->sub,a,i);
      DirEntryDel(tmpde);
    } else {
      a[*i]=tmpde;
      *i=*i+1;
    }
    tmpde=tmpde1;
  }
}

#include "/Adam/ABlkDev/FileSizeCore.HC"

public I64 FileCnt(CDirEntry *tmpde)
{//Cnt of files in $LK,"CDirEntry",A="MN:CDirEntry"$ tree.
  I64 cnt=0;
  while (tmpde) {
    if (tmpde->attr&RS_ATTR_DIR)
      cnt+=FileCnt(tmpde->sub);
    else
      cnt++;
    tmpde=tmpde->next;
  }
  return cnt;
}

#help_index "File/Cmd Line (Typically);Cmd Line (Typically)"
public I64 FF(U8 *files_find_mask,U8 *fu_flags=NULL)
{//Files find. List files matching mask.
  I64 cnt=0,fuf_flags=0;
  CDirEntry *tmpde,*tmpde1;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+r+f+F");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  tmpde=tmpde1=FilesFind(files_find_mask,fuf_flags);
  while (tmpde) {
    PutFileLink(tmpde->full_name);
    '\n';
    cnt++;
    tmpde=tmpde->next;
  }
  DirTreeDel(tmpde1);
  return cnt;
}

public I64 Zip(U8 *files_find_mask="*",U8 *fu_flags=NULL)
{//Compress files by moving to .Z filename.
  U8 *st;
  CDirEntry *tmpde,*tmpde1;
  I64 res=0,fuf_flags=0;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+r+f+F+O");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  tmpde=tmpde1=FilesFind(files_find_mask,fuf_flags);
  while (tmpde) {
    if (!IsDotZ(tmpde->full_name)) {
      st=MStrPrint("%s.Z",tmpde->full_name);
      res+=Move(tmpde->full_name,st);
      Free(st);
    }
    tmpde=tmpde->next;
  }
  DirTreeDel(tmpde1);
  return res;
}

public I64 Unzip(U8 *files_find_mask="*.Z",U8 *fu_flags=NULL)
{//Uncompress files by moving to not .Z filename.
//You don't have to do this for normal operation.
  //It automatically unzips ".Z" files.
  U8 *st;
  CDirEntry *tmpde,*tmpde1;
  I64 res=0,fuf_flags=0;
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),"+r+f+F+O");
  ScanFlags(&fuf_flags,Define("ST_FILE_UTIL_FLAGS"),fu_flags);
  tmpde=tmpde1=FilesFind(files_find_mask,fuf_flags);
  while (tmpde) {
    if (IsDotZ(tmpde->full_name)) {
      st=StrNew(tmpde->full_name);
      StrLastRem(st,".");
      res+=Move(tmpde->full_name,st);
      Free(st);
    }
    tmpde=tmpde->next;
  }
  DirTreeDel(tmpde1);
  return res;
}
