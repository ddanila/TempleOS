U0 LexIncludeStr(CCmpCtrl *cc,U8 *abs_filename,U8 *src,Bool actual_file)
{
  LexBackupLastChar(cc);
  CLexFile *tmpf=LexFilePush(cc);
  if (actual_file)
    tmpf->full_name=StrNew(abs_filename);
  else
    tmpf->full_name=StrNew(blkdev.tmp_filename);
  tmpf->line_num=1;
  tmpf->buf=tmpf->buf_ptr=tmpf->line_start=cc->cur_buf_ptr=src;
}
