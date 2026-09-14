#include "/Compiler/LexChar.HH"
I64 LexCharBody(CCmpCtrl *cc,CLexCharSource *source)
{
  I64 i,j,k,l,ch;
	k=0;
	for (j=0;j<8;j++) {
	  ch=source->read(source->context,cc);
	  if(ch<0) return -1;
	  if (!ch || ch=='\'')
	    break;
	  if (ch=='\\') {
	    ch=source->read(source->context,cc);
	    if(ch<0) return -1;
	    switch (ch) {
	      case '0':		k.u8[j]=0;	break;
	      case '\'':	k.u8[j]='\'';	break;
	      case '\`':	k.u8[j]='\`';	break;
	      case '"':		k.u8[j]='"';	break;
	      case '\\':	k.u8[j]='\\';	break;
	      case 'd':		k.u8[j]='$$';	break;
	      case 'n':		k.u8[j]='\n';	break;
	      case 'r':		k.u8[j]='\r';	break;
	      case 't':		k.u8[j]='\t';	break;
	      case 'x':
	      case 'X':
		i=0;
		for (l=0;l<2;l++) {
		  ch=source->read(source->context,cc);
		  if(ch<0) return -1;
		  ch=ToUpper(ch);
		  if (Bt(char_bmp_hex_numeric,ch)) {
		    if (ch<='9')
		      i=i<<4+ch-'0';
		    else
		      i=i<<4+ch-'A'+10;
		  } else {
		    cc->flags|=CCF_USE_LAST_U16;
		    break;
		  }
		}
		k.u8[j]=i;
		break;
	      default:
		k.u8[j]='\\';
		cc->flags|=CCF_USE_LAST_U16;
	    }
	  } else if (ch=='$$') {
	    ch=source->read(source->context,cc);
	    if(ch<0) return -1;
	    k.u8[j]='$$';
	    if (ch!='$$')
	      cc->flags|=CCF_USE_LAST_U16;
	  } else
	    k.u8[j]=ch;
	}
  if(ch!=39) {
    ch=source->read(source->context,cc);
    if(ch<0) return -1;
    if(ch && ch!=39) return -2;
  }
  cc->cur_i64=k;
  cc->token=TK_CHAR_CONST;
  return TK_CHAR_CONST;
}
