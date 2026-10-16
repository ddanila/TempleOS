Bool FileNameChk(U8 *filename)
{//Return check for valid filename, not checking existence.
  U8 *ptr=filename;
  if (!filename) return FALSE;
  if (!*ptr) return FALSE;
  if (*ptr=='.') {
    if (!ptr[1]) return TRUE;
    if (ptr[1]=='.' && !ptr[2]) return TRUE;
  }
  if (StrLen(filename)>=CDIR_FILENAME_LEN) return FALSE;
  while (*ptr)
    if (!Bt(char_bmp_filename,*ptr++))
      return FALSE;
  return TRUE;
}

