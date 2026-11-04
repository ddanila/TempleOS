I64 Del(U8 *files_find_mask,Bool make_mask=FALSE,
	Bool del_dir=FALSE,Bool print_msg=TRUE)
{//Delete files.
  I64 res=0;
  CDirContext *dirc;
  if (dirc=DirContextNew(files_find_mask,make_mask)) {
    switch (dirc->dv->fs_type) {
      case FSt_REDSEA:
	res=RedSeaFilesDel(dirc->dv,Fs->cur_dir,dirc->mask,
	      0,del_dir,print_msg);
	break;
      case FSt_FAT32:
	res=FAT32FilesDel(dirc->dv,Fs->cur_dir,dirc->mask,
	      0,del_dir,print_msg);
	break;
      default:
	PrintErr("File System Not Supported\n");
    }
    DirContextDel(dirc);
  }
  return res;
}
