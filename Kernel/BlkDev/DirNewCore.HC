Bool DirNew(CDrv *dv,U8 *cur_dir,CDirEntry *tmpde,Bool free_old_chain=TRUE)
{//Makes a directory entry in the directory from a $LK,"CDirEntry",A="MN:CDirEntry"$ node.
  switch (dv->fs_type) {
    case FSt_REDSEA:
      return RedSeaDirNew(dv,cur_dir,tmpde,free_old_chain);
    case FSt_FAT32:
      return FAT32DirNew(dv,cur_dir,tmpde,free_old_chain);
    default:
      PrintErr("File System Not Supported\n");
      return FALSE;
  }
}

