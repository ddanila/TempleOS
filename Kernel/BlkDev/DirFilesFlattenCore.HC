CDirEntry *DirFilesFlatten(CDirEntry *tmpde,CDirEntry **_res,I64 fuf_flags)
{//Returns last node
  CDirEntry *tmpde1;
  Bool del;
  if (tmpde)
    while (TRUE) {
      tmpde1=tmpde->next;
      if (!(tmpde->attr&RS_ATTR_DIR)||!(fuf_flags&FUF_JUST_FILES)) {
	_res=*_res=tmpde;
	del=FALSE;
      } else
	del=TRUE;
      if (tmpde->sub) {
	_res=DirFilesFlatten(tmpde->sub,_res,fuf_flags);
	tmpde->sub=NULL;
      }
      if (del)
	DirEntryDel(tmpde);
      if (tmpde1)
	tmpde=tmpde1;
      else
	break;
    }
  *_res=NULL;
  return _res;
}

