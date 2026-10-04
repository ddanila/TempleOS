U0 StrPrintFunSeg(U8 *buf,I64 addr,I64 field_len,I64 flags)
{
  I64 offset;
  CHashExport *tmpex;
  U8 *str,*str2;
  Bool is_fun=FALSE;
  if (!(flags&PRTF_TRUNCATE))
    field_len=0;
  if (addr) {
    if (str=FunSegCacheFind(addr,&offset)) {
      if (addr!=SYS_IDLE_PT)
	is_fun=TRUE;
    } else  {
      if (tmpex=FunSegFind(addr,&offset)) {
	if (tmpex->type&HTT_FUN)
	  is_fun=TRUE;
	FunSegCacheAdd(tmpex,addr);
	str=tmpex->str;
      }
    }
    if (str) {
      if (offset>0xFFFF) offset=0xFFFF;
      if (flags&PRTF_COMMA) {
	if (is_fun) {
	  str2=MStrPrint("&%s",str);
	  if (!field_len)
	    StrCpy(buf,str2);
	  else if (flags&PRTF_LEFT_JUSTIFY && StrLen(str2)<field_len)
	    StrCpy(buf,str2);
	  else
	    StrPrint(buf,"%*ts",field_len,str2);
	  Free(str2);
	} else {
	  if (!field_len)
	    StrCpy(buf,str);
	  else if (flags&PRTF_LEFT_JUSTIFY && StrLen(str)<field_len)
	    StrCpy(buf,str);
	  else
	    StrPrint(buf,"%*ts",field_len,str);
	}
      } else {
	if (is_fun) {
	  str2=MStrPrint("&%s",str);
	  if (field_len && field_len>7) {
	    if (flags&PRTF_LEFT_JUSTIFY && StrLen(str2)<field_len-7)
	      StrPrint(buf,"%s+0x%04X",str2,offset);
	    else
	      StrPrint(buf,"%*ts+0x%04X",field_len-7,str2,offset);
	  } else
	    StrPrint(buf,"%s+0x%04X",str2,offset);
	  Free(str2);
	} else {
	  if (field_len && field_len>7) {
	    if (flags&PRTF_LEFT_JUSTIFY && StrLen(str)<field_len-7)
	      StrPrint(buf,"%s+0x%04X",str,offset);
	    else
	      StrPrint(buf,"%*ts+0x%04X",field_len-7,str,offset);
	  } else
	    StrPrint(buf,"%s+0x%04X",str,offset);
	}
      }
      return;
    }
  }
  if (flags&PRTF_COMMA)
    StrCpy(buf,".");
  else if (flags&PRTF_TRUNCATE && field_len)
    StrPrint(buf,"%*tX",field_len,addr);
  else
    StrPrint(buf,"%X",addr);
}

