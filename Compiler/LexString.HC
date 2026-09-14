#include "/Compiler/LexString.HH"
I64 LexStringChunk(CCmpCtrl *cc,U8 *buf,I64 size,Bool *done,CLexCharSource *source)
{
  I64 i=0,j,k,ch;
  *done=TRUE;
  while (i<size-1) {
    ch=source->read(source->context,cc);
    if(ch<0) goto lex_string_error;
    if (!ch || ch=='"') {
      buf[i++]=0;
      return i;
    } else if (ch=='\\') {
      ch=source->read(source->context,cc);
      if(ch<0) goto lex_string_error;
      switch (ch) {
	case '0':
	  buf[i++]=0;
	  break;
	case '\'':
	  buf[i++]='\'';
	  break;
	case '\`':
	  buf[i++]='\`';
	  break;
	case '\\':
	  buf[i++]='\\';
	  break;
	case '"':
	  buf[i++]='"';
	  break;
	case 'd':
	  buf[i++]='$$';
	  break;
	case 'n':
	  buf[i++]='\n';
	  break;
	case 'r':
	  buf[i++]='\r';
	  break;
	case 't':
	  buf[i++]='\t';
	  break;
	case 'x':
	case 'X':
	  j=0;
	  for (k=0;k<2;k++) {
	    ch=source->read(source->context,cc);
	    if(ch<0) goto lex_string_error;
	    ch=ToUpper(ch);
	    if (Bt(char_bmp_hex_numeric,ch)) {
	      if (ch<='9')
		j=j<<4+ch-'0';
	      else
		j=j<<4+ch-'A'+10;
	    } else {
	      cc->flags|=CCF_USE_LAST_U16;
	      break;
	    }
	  }
	  buf[i++]=j;
	  break;
	default:
	  cc->flags|=CCF_USE_LAST_U16;
	  buf[i++]='\\';
      }
    } else if (ch=='$$') {
      buf[i++]='$$';
      if (cc->dollar_cnt)
	cc->dollar_cnt--;
      else {
        ch=source->read(source->context,cc);
        if(ch<0) goto lex_string_error;
        if(ch!='$$') {
          cc->dollar_cnt=1;
          cc->flags|=CCF_USE_LAST_U16;
        }
      }
    } else
      buf[i++]=ch;
  }
  *done=FALSE;
  return i;
lex_string_error:
  *done=FALSE;
  return -1;
}
