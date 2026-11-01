U0 DirEntryDel(CDirEntry *tmpde)
{//Free node returned from $LK,"FilesFind",A="MN:FilesFind"$().  Doesn't Free user_data.
//Does not change the directory on disk.
  if (tmpde) {
    Free(tmpde->full_name);
    Free(tmpde);
  }
}

U0 DirEntryDel2(CDirEntry *tmpde)
{//Free node returned from $LK,"FilesFind",A="MN:FilesFind"$().  Frees user_data
//Does not change the directory on disk.
  if (tmpde) {
    Free(tmpde->full_name);
    Free(tmpde->user_data);
    Free(tmpde);
  }
}

U0 DirTreeDel(CDirEntry *tmpde)
{//Free tree returned from $LK,"FilesFind",A="MN:FilesFind"$().  Doesn't Free user_data.
//Does not change the directory on disk.
  CDirEntry *tmpde2;
  while (tmpde) {
    tmpde2=tmpde->next;
    if (tmpde->sub)
      DirTreeDel(tmpde->sub);
    DirEntryDel(tmpde);
    tmpde=tmpde2;
  }
}

U0 DirTreeDel2(CDirEntry *tmpde)
{//Free tree returned from $LK,"FilesFind",A="MN:FilesFind"$().  Frees user_data
//Does not change the directory on disk.
  CDirEntry *tmpde2;
  while (tmpde) {
    tmpde2=tmpde->next;
    if (tmpde->sub)
      DirTreeDel2(tmpde->sub);
    DirEntryDel2(tmpde);
    tmpde=tmpde2;
  }
}

