CDirEntry *FilesFind2(U8 *files_find_mask,I64 fuf_flags)
{
  CDrv *dv=Fs->cur_dv;
  CDirEntry *res=NULL;
  DrvChk(dv);
  switch (dv->fs_type) {
    case FSt_REDSEA:
      res=RedSeaFilesFind(files_find_mask,fuf_flags);
      break;
    case FSt_FAT32:
      res=FAT32FilesFind(files_find_mask,fuf_flags);
      break;
    default:
      PrintErr("File System Not Supported\n");
      res=NULL;
  }
  if (res) {
    DirFilesSort(&res,SK_NAME);
    if (fuf_flags&(FUF_FLATTEN_TREE|FUF_JUST_FILES))
      DirFilesFlatten(res,&res,fuf_flags);
    if (fuf_flags&FUF_CLUS_ORDER)
      DirFilesSort(&res,SK_CLUS);
  }
  return res;
}

CDirEntry *FilesFind(U8 *files_find_mask,I64 fuf_flags=0)
{/* See $LK,"::/Doc/FileUtils.DD"$.

Find files and make a directory tree in memory.

When done, you free with $LK,"DirEntryDel",A="MN:DirEntryDel"$(),$LK,"DirEntryDel2",A="MN:DirEntryDel2"$(),
$LK,"DirTreeDel",A="MN:DirTreeDel"$() or $LK,"DirTreeDel2",A="MN:DirTreeDel2"$().

*/
  CDirEntry *res;
  CDirContext *dirc;
  if (fuf_flags&~FUG_FILES_FIND)
    throw('FUF');
  if (fuf_flags&FUF_SINGLE) {
    res=MAlloc(sizeof(CDirEntry));
    if (!FileFind(files_find_mask,res)) {
      Free(res);
      return NULL;
    }
  } else if (dirc=DirContextNew(files_find_mask,TRUE)) {
    res=FilesFind2(dirc->mask,fuf_flags);
    DirContextDel(dirc);
  } else
    return NULL;
  return res;
}
