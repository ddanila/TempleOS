public Bool Ed(U8 *link_st,I64 edf_dof_flags=0)
{//Invoke document editor.
  U8 *filename,*needle_str;
  I64 i,num;
  Bool cont,res=FALSE;
  CDoc *doc;

  switch (i=EdLinkCvt(link_st,&filename,&needle_str,&num,edf_dof_flags)) {
    case -1:
      break;
    case LK_DEF:
      doc=DocNew;
      doc->desc='DictDef';
      ACDDefsPut(doc,filename,num);
      goto ej_doc;
    case LK_HELP_INDEX:
      doc=DocNew;
      doc->desc='HelpIndx';
      DocHelpIdx(doc,filename);
ej_doc:
      if (!(edf_dof_flags&EDF_BAIL)) {
	DocEd(doc);
	DocDel(doc);
      }
      if (!(edf_dof_flags&EDF_WAS_WRITE))
	res=TRUE;
      break;
    default:
      if (IsRaw)
	res=EdLite(filename,num,edf_dof_flags);
      else {
	cont=TRUE;
	if (!(edf_dof_flags&EDF_BAIL) && !(LK_DOC<=i<=LK_DOC_LINE) &&
	      !FilesFindMatch(filename,FILEMASK_TXT) &&
	      !PopUpCancelOk(ST_WARN_ST "Not Text File\n\n"))
	  cont=FALSE;
	if (cont)
	  res=DocFileEd(i,filename,needle_str,&num,edf_dof_flags);
      }
  }
  Free(filename);
  Free(needle_str);
  return res;
}

public Bool Plain(U8 *filename,I64 edf_dof_flags=0)
{//Edit document in plain text mode, so dollar signs are not special.
  Bool res;
  U8 *st=MStrPrint("PI:%s",filename);
  res=Ed(st,edf_dof_flags);
  Free(st);
  return res;
}
