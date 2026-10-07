I64 StrOcc(U8 *src, I64 ch)
{//Count occurrences of a char.
  I64 i=0;
  if (!src) return 0;
  while (*src)
    if (*src++==ch)
      i++;
  return i;
}

I64 Spaces2Tabs(U8 *dst,U8 *src)
{//Src buf with spaces to dst buf without.
  U8 *src2;
  I64 chged=0,space_cnt,space_cnt2,col=0;
  if (*src)
    while (TRUE) {
      src2=src;
      while (*src2==CH_SPACE)
	src2++;
      space_cnt=src2-src;
      while (col+space_cnt>=8) {
	space_cnt2=8-col;
	if (space_cnt2==1)
	  *dst++=CH_SPACE;
	else {
	  *dst++='\t';
	  chged+=space_cnt2-1;
	}
	space_cnt-=space_cnt2;
	col=0;
      }
      if (*src2=='\t') {
	if (space_cnt==1 && col==7)
	  *dst++=CH_SPACE;
	else
	  chged+=space_cnt;
	*dst++='\t';
	col=0;
      } else {
	while (space_cnt--) {
	  *dst++=CH_SPACE;
	  if (++col==8)
	    col=0;
	}
	if (*src2) {
	  *dst++=*src2;
	  if (++col==8)
	    col=0;
	} else
	  break;
      }
      src=++src2;
    }
  *dst=0;
  return chged;
}

U8 *StrUtil(U8 *_src,I64 flags)
{//Modifies in place. See $LK,"flags",A="MN:SUF_REM_SPACES"$ for all the options.
  U8 *src=_src,*dst=_src;
  I64 ch;

  if (flags & SUF_REM_LEADING)
    while (Bt(char_bmp_white_space,*src))
      src++;
  while (ch=*src++)
    if (Bt(char_bmp_white_space,ch)) {
      if (!(flags & SUF_REM_SPACES)) {
	if (flags & SUF_SINGLE_SPACE) {
	  *dst++ = CH_SPACE;
	  while ((ch=*src++) && Bt(char_bmp_white_space,ch));
	  src--;
	} else
	  *dst++ = ch;
      }
    } else if (!(flags & SUF_REM_CTRL_CHARS) || ch>=CH_SHIFT_SPACE)
      *dst++=ch;
  *dst=0;

  if (flags & SUF_REM_TRAILING)
    while (dst!=_src && (!*dst || Bt(char_bmp_white_space,*dst)))
      *dst-- =0;
  if (flags & SUF_TO_UPPER)
    for (dst=_src;*dst;dst++) {
      ch=*dst;
      if ('a'<=ch<='z')
	*dst=ch-0x20;
    }
  if (flags & SUF_TO_LOWER)
    for (dst=_src;*dst;dst++) {
      ch=*dst;
      if ('A'<=ch<='Z')
	*dst=ch+0x20;
    }
  if (flags & SUF_SAFE_DOLLAR)
    for (dst=_src;*dst;dst++) {
      ch=*dst;
      if (!Bt(char_bmp_safe_dollar,*dst))
	*dst='.';
    }
  if (flags & SUF_S2T)
    Spaces2Tabs(_src,_src);
  return _src;
}

U8 *StrFirstOcc(U8 *src,U8 *marker)
{//Point to 1st occurrence of marker set in str.
  I64 ch;
  while ((ch=*src++) && !StrOcc(marker,ch));
  if (ch)
    return src-1;
  else
    return NULL;
}

U8 *StrFirstRem(U8 *src,U8 *marker,U8 *dst=NULL)
{//Remove first str segment and place in dst buf or NULL.
  I64 ch;
  U8 *ptr=src,*res=dst;
  if (dst) {
    while ((ch=*ptr++) && !StrOcc(marker,ch))
      *dst++=ch;
    *dst=0;
  } else
    while ((ch=*ptr++) && !StrOcc(marker,ch));
  if (ch)
    StrCpy(src,ptr);
  else
    *src=0;
  return res;
}

