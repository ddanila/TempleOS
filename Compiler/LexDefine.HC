#include "/Compiler/LexDefine.HH"
I64 LexDefineChar(CCmpCtrl *cc,CLexCharSource *source,Bool *failed)
{
  I64 ch;
  if(*failed) return 0;
  ch=(*source->read)(source->context,cc);
  if(ch<0) { *failed=TRUE; return 0; }
  return ch;
}
Bool LexDefineRead(CCmpCtrl *cc,CLexCharSource *source,CLexDefineSink *sink)
{
  I64 ch,j; U8 buf[STR_LEN]; Bool in_str,failed=FALSE;
  if(!cc || !source || !source->read || !sink || !sink->append) return FALSE;
	      do ch=LexDefineChar(cc,source,&failed); //skip space between define name and start
	      while (Bt(char_bmp_non_eol_white_space,ch));

	      j=0;
	      if (ch) {
		in_str=FALSE;
		do {
		  if (ch=='\\') {
		    if (ch=LexDefineChar(cc,source,&failed)) {
		      if (ch!='\r' && ch!='\n') {
			buf[j++]='\\';
			buf[j++]=ch;
		      } else if (ch=='\r' && LexDefineChar(cc,source,&failed)!='\n')
			cc->flags|=CCF_USE_LAST_U16;
		    } else {
		      buf[j++]='\\';
		      break;
		    }
		  } else if (ch!='\n') {
		    if (ch=='\"')
		      in_str=!in_str;
		    buf[j++]=ch;
		  } else
		    break;
		  while (ch=LexDefineChar(cc,source,&failed)) {
		    if (ch=='/') {
		      ch=LexDefineChar(cc,source,&failed);
		      if (ch=='/' && !in_str) {
			do ch=LexDefineChar(cc,source,&failed);
			while (Bt(char_bmp_non_eol,ch));
			break;
		      } else {
			buf[j++]='/';
			cc->flags|=CCF_USE_LAST_U16;
		      }
		    } else if (ch=='\\') {
		      if (ch=LexDefineChar(cc,source,&failed)) {
			if (ch=='\"') {
			  buf[j++]='\\';
			  buf[j++]=ch;
			} else {
			  cc->flags|=CCF_USE_LAST_U16;
			  ch='\\';
			  break;
			}
		      }
		    } else if (Bt(char_bmp_non_eol,ch)) {
		      if (ch=='\"')
			in_str=!in_str;
		      buf[j++]=ch;
		    } else
		      break;
		    if (j>=STR_LEN-4) {//Spot for ['\'][ch],[ch],[0]
		      buf[j++]=0;
		      if(!(*sink->append)(sink->context,buf,j)) return FALSE;
		      j=0;
		    }
		  }
		} while (ch=='\\');
	      }
      if(failed) return FALSE;
      buf[j++]=0;
      return (*sink->append)(sink->context,buf,j);
}
