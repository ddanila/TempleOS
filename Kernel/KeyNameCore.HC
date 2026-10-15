U8 *Char2KeyName(I64 ch,Bool include_ctrl=TRUE)
{//ASCII val to key name.
  I64 i;
  U8 buf[STR_LEN];
  *buf=0; //The no-CTRL-prefix path must not append to uninitialized stack data.
  if (ch<=CH_SPACE) {
    switch [ch] {
      case '\n':
	StrCpy(buf,"ENTER");
	break;
      case CH_BACKSPACE:
	StrCpy(buf,"BACKSPACE");
	break;
      case '\t':
	StrCpy(buf,"TAB");
	break;
      case CH_ESC:
	StrCpy(buf,"ESC");
	break;
      case CH_SHIFT_ESC:
	StrCpy(buf,"SHIFT_ESC");
	break;
      case 0: //nobound switch
      case 29:
      case 30:
	*buf=0;
	break;
      case CH_SHIFT_SPACE:
	StrCpy(buf,"SHIFT_SPACE");
	break;
      case CH_SPACE:
	StrCpy(buf,"SPACE");
	break;
      default:
	if (include_ctrl)
	  StrCpy(buf,"CTRL ");
	buf[i=StrLen(buf)]=ch-1+'a';
	buf[i+1]=0;
	break;
    }
  } else if (Bt(char_bmp_printable,ch)) {
    *buf=ch;
    buf[1]=0;
  } else
    *buf=0;
  return StrNew(buf);
}

